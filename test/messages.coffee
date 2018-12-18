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
      "hash1": Buffer.from("12345678", "hex")
      "hash2": Buffer.from("90ABCDEF", "hex")
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
      key1: Buffer.from("hash1")
      key2: Buffer.from("hash2")
      key3: Buffer.from("hash3")

    for key, hash of keys_and_hashes
      msgs.addHash(hash)
      msgs.packets.packet[msgs.packets.packet.length - 1].packet["fromKey"]={key: key}
    assert.deepEqual msgs.getHashes(), keys_and_hashes_answer
    do done
