{ equal: eq, throws } = require 'assert'

messages = require '../src/messages.coffee'


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
