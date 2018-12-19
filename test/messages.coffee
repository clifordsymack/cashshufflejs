# { equal: eq, throws } = require 'assert'
assert = require 'assert'
eq = assert.equal

messages = require '../src/messages.coffee'
BCH = require('bitcoincashjs-fork')

eck = new BCH.PrivateKey("L23PpjkBQqpAF4vbMHNfTZAb3KFPBSawQ7KinFTzz7dxq6TZX8UA")
address = eck.toAddress().toString()

describe "Messages", ->

  it 'should have a packets after creation', (done) ->
    msgs = new messages
    if msgs.packets
      do done

  it 'should get a last packet', (done) ->
    msgs = new messages
    try
      msgs.lastPacket()
    catch error
      eq error.message, 'no last packet'
    msgs.addStr("1")
    lastPacket = msgs.lastPacket()
    eq msgs.packets.packet[0].packet.message.str, "1"
    do done

  it 'should make a greeting message from verification key and amount', (done) ->
    msgs = new messages
    someKey = "somekey"
    amount = 12345
    msgs.makeGreeting someKey, amount
    eq msgs.packets.packet[0].packet.fromKey.key, someKey
    eq msgs.packets.packet[0].packet.registration.amount, amount
    do done

  it 'should form a packet', (done) ->
    msgs = new messages
    session = new Buffer('somesession')
    number = 1
    vkFrom = "key from"
    vkTo = "key to"
    phase = "announcement"
    msgs.makeGreeting "1", 1
    msgs.formAllPackets eck, session, number, vkFrom, vkTo, phase
    for packet in msgs.packets.packet
      eq packet.packet.session, session
      eq packet.packet.number, number
      eq packet.packet.fromKey.key, vkFrom
      eq packet.packet.toKey.key, vkTo
      # Add signature verification later!
    do done

  it 'should add an encryption key', (done) ->
    msgs = new messages
    ek = 'some encryption key'
    change = 'some change'
    msgs.addEncryptionKey(ek, null)
    eq msgs.packets.packet[0].packet.message.key.key, ek
    do msgs.clearPackets
    msgs.addEncryptionKey(ek, change)
    eq msgs.packets.packet[0].packet.message.key.key, ek
    eq msgs.packets.packet[0].packet.message.address.address, change
    do done

  it 'should add an inputs', (done) ->
    msgs = new messages
    inputs =
      'pubkey_1': [ "hash11", "hash12" ]
      'pubkey_2': [ "hash21", "hash22" ]
    msgs.addInputs inputs
    for key, val of msgs.packets.packet[0].packet.message.inputs
      assert key of inputs
      eq val.coins, inputs[key]
    do done

  it 'should add str', (done) ->
    msgs = new messages
    str = "string"
    msgs.addStr str
    eq str, msgs.packets.packet[0].packet.message.str
    do done

  it 'should add hash', (done) ->
    msgs = new messages
    hash = Buffer.from("hash")
    msgs.addHash hash
    eq hash, msgs.packets.packet[0].packet.message.hash.hash
    do done

  it 'should add signatures', (done) ->
    msgs = new messages
    signatures =
      "hash1": Buffer.from "12345678", "hex"
      "hash2": Buffer.from "90ABCDEF", "hex"
    msgs.addSignatures signatures
    for signature in msgs.packets.packet[0].packet.message.signatures
      assert signature.utxo of signatures
      eq signature.signature.signature, signatures[signature.utxo]
    do done

  it 'should get new addresses', (done) ->
    msgs = new messages
    addresses = ["first_address", "second_address", "third_address"]
    msgs.addStr address for address in addresses
    assert.deepEqual msgs.getNewAddresses(), addresses
    do done

  it 'should get hashes', (done) ->
    msgs = new messages
    keys_and_hashes_answer =
      key1: "hash1"
      key2: "hash2"
      key3: "hash3"
    keys_and_hashes =
      key1: Buffer.from "hash1"
      key2: Buffer.from "hash2"
      key3: Buffer.from "hash3"
    for key, hash of keys_and_hashes
      msgs.addHash(hash)
      msgs.packets.packet[msgs.packets.packet.length - 1].packet["fromKey"]={key: key}
    assert.deepEqual msgs.getHashes(), keys_and_hashes_answer
    do done

  it 'should get signatures and packets', (done) ->
    # add checking for signatures
    msgs = new messages
    strs = ["1", "2"]
    msgs.addStr(str) for str in ["1", "2"]
    msgs.formAllPackets eck, "session", 1, "vkFrom", "vkTo", "announcement"
    res = msgs.getSignaturesAndPackets()
    for item in res
      eq item[2], "vkFrom"
    do done

  it 'should get players', (done) ->
    msgs = new messages
    msgs.addStr("_") for _ in [1..3]
    for packet, index in msgs.packets.packet
      packet.packet.number = index + 1
      packet.packet["fromKey"] = { key:"key of #{index + 1}"}
    players = msgs.getPlayers()
    # Note that due to JS nature keys are strings, not numbers!
    assert.deepEqual players, {"1": "key of 1" ,"2": "key of 2", "3": "key of 3"  }
    do done

  it 'should get blames', (done) ->
    msgs = new messages
    msgs.addStr(index) for index in [1..3]
    blames = msgs.getBlame()
    # don't sure how to check it correctlly
    eq blames.length, 3
    do done

  it 'should get strs', (done) ->
    msgs = new messages
    strs = ["1", "2", "3"]
    msgs.addStr(str) for str in strs
    assert.deepEqual msgs.getStrs(), strs
    do done

  it 'should get session', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    session = Buffer.from("session")
    msgs.packets.packet[1].session = session
    eq msgs.getSession(), session
    do done

  it 'should get number', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    number = 1
    msgs.packets.packet[1].packet.number = number
    eq msgs.getNumber(), number
    do done

  it 'should get Encryption Key', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    key = "key"
    msgs.packets.packet[1].packet.message["key"] = {key: key}
    eq msgs.getEncryptionKey(), key
    do done

  it 'should get Address', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    address = "address"
    msgs.packets.packet[1].packet.message["address"] = {address: address}
    eq msgs.getAddress(), address
    do done

  it 'should get fromKey', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    fromKey = "fromKey"
    msgs.packets.packet[1].packet.message["fromKey"] = {key: fromKey}
    eq msgs.getFromKey(), fromKey
    do done

  it 'should get toKey', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    toKey = "toKey"
    msgs.packets.packet[1].packet.message["toKey"] = {key: toKey}
    eq msgs.getToKey(), toKey
    do done

  it 'should get phase', (done) ->
    msgs = new messages
    msgs.addStr("1")
    msgs.addStr("1")
    phase = 1
    msgs.packets.packet[1].packet.phase = phase
    eq msgs.getPhase(), phase
    do done

  it 'should get hash', (done) ->
    msgs = new messages
    msgs.addStr("1")
    hash = Buffer.from("hash")
    msgs.addHash(hash)
    eq msgs.getHash(), hash
    do done

  it 'should get str', (done) ->
    msgs = new messages
    msgs.addStr("1")
    str = Buffer.from("hash")
    msgs.addStr(str)
    eq msgs.getStr(), str
    do done
