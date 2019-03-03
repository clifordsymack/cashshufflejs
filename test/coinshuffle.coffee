assert = require 'assert'
eq = assert.equal

Round = require '../src/coinshuffle.coffee'

Coin = require '../src/coin.coffee'
Messages = require '../src/messages.coffee'
Crypto = require '../src/crypto.coffee'
Comms = require '../src/comms.coffee'


describe "CoinShuffle", ->

  it 'should initialize round object', (done)->
    # initialize object
    round = new Round
    # initialize miscellance
    coin = new Coin
    crypto = new Crypto
    messages = new Messages
    # set up miscellance
    round.setUpMisc coin, messages, crypto
    # check equiality of miscs
    eq round.crypto, crypto
    eq round.messages, messages
    eq round.coin, coin
    # initialize channels


    console.log round
    do done
