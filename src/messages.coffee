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
      packet.packet.phase = Phase.values[do phase.toUpperCase]
      packet.packet.session = session
      packet.packet.number = number
      packet.packet.fromKey = VerificationKey.create {from_key: vkFrom}
      if vkTo
        packet.packet.toKey = VerificationKey.create {to_key: vkTo}
      msg = Packet.encode packet.packet
            .finish()
            .toString 'base64'
      sig = BchMessage msg
            .sign eck
      sig_bytes = Buffer.from sig, "base64"
      packet.signature = Signature.create {signature: sig_bytes}


  # generalBlame: (accused) ->

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

  clearPackets: () ->
    @packets = Packets.create {packet: []}

  serialize: () ->
    Packets.encode @packets
    .finish()

  deserialize: (buffer) ->
    @packets = Packets.decode(buffer)

module.exports = Messages
