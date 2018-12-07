protobuf = require 'protobufjs'

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

  formAllPackets: (eck, session, number, vkFrom, vkTo, phase)->
    # TBD
    return  


module.exports = Messages
