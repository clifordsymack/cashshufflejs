protobuf = require 'protobufjs'
BchMessage = require('bitcoincashjs-fork').Message

message_root = protobuf.loadSync("./protobuf/message.proto")


Signed = message_root.lookupType "Signed"
Packet = message_root.lookupType "Packet"
Phase = message_root.lookupEnum "Phase"
Coins = message_root.lookupType "Coins"
Signatures = message_root.lookupType "Signatures"
Message = message_root.lookupType "Message"
Address = message_root.lookupType "Address"
Registration = message_root.lookupType "Registration"
VerificationKey = message_root.lookupType "VerificationKey"
EncryptionKey = message_root.lookupType "EncryptionKey"
DecryptionKey = message_root.lookupType "DecryptionKey"
Hash = message_root.lookupType "Hash"
Signature = message_root.lookupType "Signature"
Transaction = message_root.lookupType "Transaction"
Blame = message_root.lookupType "Blame"
Reason = message_root.lookupEnum "Reason"
Invalid = message_root.lookupType "Invalid"
Inputs = message_root.lookupType "Inputs"
Packets = message_root.lookupType "Packets"

valOrNull = () -> (method) -> ->
  try
    method.apply @, arguments
  catch error
    null

class Messages

  constructor: () ->
    @packets = Packets.create {packet: []}

  makeGreeting: (key, amount) ->
    message =
      Signed.create
        packet: Packet.create
          fromKey: VerificationKey.create
            key: key
          registration: Registration.create
            amount: amount
    @packets.packet.push message

  formAllPackets: (eck, session, number, vkFrom, vkTo, phase) ->
    for packet in @packets.packet
      packet.packet.phase = Phase.values[phase.toUpperCase()]
      packet.packet.session = session
      packet.packet.number = number
      packet.packet.fromKey = VerificationKey.create {key: vkFrom}
      if vkTo
        packet.packet.toKey = VerificationKey.create {key: vkTo}
      msg = Packet.encode packet.packet
            .finish()
            .toString 'base64'
      sig = BchMessage msg
            .sign eck
      sig_bytes = Buffer.from sig, "base64"
      packet.signature = Signature.create {signature: sig_bytes}

  generalBlame: (reason, accused) ->
    @clearPackets()
    packet = Signed.create
      packet: Packet.create
        message: Message.create
          blame : Blame.create
            accused: VerificationKey.create
              key: accused
        phase: Phase.values["BLAME"]
    if reason.toString() in Object.keys(Reason.valuesById)
      packet.packet.message.blame.reason = Reason.valuesById[reason.toString()]
    @packets.packet.push packet

  blameTheLiar: (accused) ->
    @generalBlame Reason.values["LIAR"] ,accused

  blameInsufficientFunds: (accused) ->
    @generalBlame Reason.values["INSUFFICIENTFUNDS"] ,accused

  blameEquivocationFailure: (accused, invalidPackets=null) ->
    @generalBlame Reason.values["EQUIVOCATIONFAILURE"] ,accused
    if invalidPackets
      @lastPacket().packet.message.blame.invalid = Invalid.create {invalid: invalidPackets}

  blameMissingOutputs: (accused) ->
    @generalBlame Reason.values["MISSINGOUTPUT"] ,accused

  blameShuffleFailure: (accused, hash) ->
    @generalBlame Reason.values["SHUFFLEFAILURE"] ,accused
    @lastPacket().packet.message.hash = Hash.create { hash: hash}

  blameShuffleAndEquivocationFailure: (accused, encryptionKey, decryptionKey, invalidPackets) ->
    @generalBlame Reason.values["SHUFFLEANDEQUIVOCATIONFAILURE"] ,accused
    @lastPacket().packet.message.blame.invalid = Invalid.create {invalid: invalidPackets}
    @lastPacket().packet.message.blame.key = DecryptionKey.create
      key: decryptionKey
      public: encryptionKey

  blameInvalidSignature: (accused) ->
    @generalBlame Reason.values["INVALIDSIGNATURE"] ,accused

  blameWrongTransactionSignature: (accused) ->
    @generalBlame Reason.values["INVALIDSIGNATURE"] ,accused

  addEncryptionKey: (ek, change) ->
    packet =
      Signed.create
        packet: Packet.create
          message: Message.create
            key: EncryptionKey.create
              key: ek
    if change
      packet.packet.message.address = Address.create {address: change}
    @packets.packet.push packet


  addInputs: (inputsObject) ->
    packet = Signed.create
      packet: Packet.create
        message: Message.create
          inputs: {}
    for key, val of inputsObject
      packet.packet.message.inputs[key] = Coins.create {coins: val}
    @packets.packet.push packet

  addStr: (str) ->
    packet = Signed.create
      packet: Packet.create
        message: Message.create
          str: str
    @packets.packet.push packet

  addHash: (hash) ->
    packet = Signed.create
      packet: Packet.create
        message: Message.create
          hash: Hash.create
            hash: hash
    @packets.packet.push packet

  addSignatures: (signatures) ->
    packet = Signed.create
      packet: Packet.create
        message: Message.create
          signatures: []
    for key, val of signatures
      packet.packet.message.signatures.push Signature.create
          utxo: key
          signature: Signature.create {signature: val}
    @packets.packet.push packet

  getNewAddresses: () ->
    packet.packet.message.str for packet in @packets.packet

  getHashes: () ->
    hashes = {}
    for packet in @packets.packet
      hashes[packet.packet.fromKey.key] = packet.packet.message.hash.hash.toString('utf8')
    hashes

  getSignaturesAndPackets: () ->
    [
      packet.signature.signature
      Packet.encode(packet.packet).finish()
      packet.packet.fromKey.key
    ] for packet in @packets.packet

  getPlayers: () ->
    players = {}
    for packet in @packets.packet
      players[packet.packet.number] = packet.packet.fromKey.key
    players

  getBlame: () ->
    packet.packet.message for packet in @packets.packet

  getStrs: () ->
    packet.packet.message.str for packet in @packets.packet

  getSession: valOrNull() ->
    @lastPacket().session

  getNumber: valOrNull() ->
    @lastPacket().packet.number

  getEncryptionKey: valOrNull() ->
    @lastPacket().packet.message.key.key

  getAddress: valOrNull() ->
    @lastPacket().packet.message.address.address

  getFromKey: valOrNull() ->
    @lastPacket().packet.message.fromKey.key

  getToKey: valOrNull() ->
    @lastPacket().packet.message.toKey.key

  getPhase: valOrNull() ->
    @lastPacket().packet.phase

  getHash: valOrNull() ->
    @lastPacket().packet.message.hash.hash

  getStr: valOrNull() ->
    @lastPacket().packet.message.str

  getInputs: valOrNull() ->
    result = {}
    for pubkey, val of @lastPacket().packet.message.inputs
      result[pubkey] = val.coins
    result

  getSignatures: valOrNull() ->
    result = {}
    for signature in @lastPacket().packet.message.signatures
      result[signature.utxo] = signature.signature.signature # Amen!
    # console.log @lastPacket().packet.message.signatures
    result

  getBlameReason: valOrNull() ->
    @lastPacket().packet.message.blame.reason

  getAccusedKey: valOrNull() ->
    @lastPacket().packet.message.blame.accused.key

  getInvalidPackets: valOrNull() ->
    @lastPacket().packet.message.blame.invalid.invalid

  getPublicKey: valOrNull() ->
    @lastPacket().packet.message.blame.key.public

  getDecryptionKey: valOrNull() ->
    @lastPacket().packet.message.blame.key.key


#========== misc ==================

  shufflePackets: () ->
  # i got it from cookbook https://coffeescript-cookbook.github.io/chapters/arrays/shuffling-array-elements
    i = @packets.packet.length
    while --i > 0
      j= ~~(Math.random() * (i + 1))
      t = @packets.packet[j]
      @packets.packet[j] = @packets.packet[i]
      @packets.packet[i] = t

  lastPacket: () ->
    if @packets.packet.length
      @packets.packet[@packets.packet.length - 1]
    else
      throw new Error('no last packet')

  clearPackets: () ->
    @packets = Packets.create {packet: []}

  serialize: () ->
    Packets.encode @packets
    .finish()

  deserialize: (buffer) ->
    @packets = Packets.decode(buffer)

#============== Export ==============

module.exports = Messages
