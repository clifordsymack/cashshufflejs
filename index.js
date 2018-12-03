console.log("Checking for protobuf")

var protobuf = require("protobufjs");

protobuf.load("protobuf/message.proto", function(err, root) {
    if (err)
        throw err;

    // // Obtain a message type
    var Signed = root.lookupType("Signed");
    var Packet = root.lookupType("Packet")
    var Phase = root.lookupEnum("Phase")
    var Coins = root.lookupType("Coins")
    var Signatures = root.lookupType("Signatures")
    var Message = root.lookupType("Message")
    var Address = root.lookupType("Address")
    var Registration = root.lookupType("Registration")
    var VerificationKey = root.lookupType("VerificationKey")
    var EncryptionKey = root.lookupType("EncryptionKey")
    var DecryptionKey = root.lookupType("DecryptionKey")
    var Hash = root.lookupType("Hash")
    var Signature = root.lookupType("Signature")
    var Transaction = root.lookupType("Transaction")
    var Blame = root.lookupType("Blame")
    var Reason = root.lookupEnum("Reason")
    var Invalid = root.lookupType("Invalid")
    var Inputs = root.lookupType("Inputs")
    var Packets = root.lookupType("Packets")

    var message = Signed.create({
      packet: Packet.create({
        fromKey: VerificationKey.create({key: "somekeygoeshere"}),
        registration: Registration.create({amount: 1000})
      })
    });

    var packets = Packets.create({packet: [message]})
    var buffer = Packets.encode(packets).finish()

    console.log(buffer)
});
