assert = require 'assert'
eq = assert.equal

Crypto = require '../src/crypto.coffee'


describe "Crypto", ->

  it 'should generate key pair', (done) ->
    crypto = new Crypto
    crypto.generateKeyPair()
    assert.ok crypto.privateKey isnt null
    do done

  it 'shoulde export private key as a string', (done) ->
    crypto = new Crypto
    crypto.generateKeyPair()
    assert.ok crypto.exportPrivareKey()
    do done

  it 'shoulde restore keypair from private key as a hex string', (done) ->
    crypto = new Crypto
    secret = "e5d885337f78a71b1cf0d2a799c794d79e1874269a4fb34c7661227f9499b94d"
    crypto.restoreFromPrivateKey secret
    eq crypto.exportPrivareKey(), secret
    do done

  it 'should export public key as hex string', (done) ->
    crypto = new Crypto
    secret = "e5d885337f78a71b1cf0d2a799c794d79e1874269a4fb34c7661227f9499b94d"
    publicHex = "025ed0e6cdefebd4004e429f88ffe949f6d17d9e8e4296846a3e2c9d5ea8ca0682"
    crypto.restoreFromPrivateKey secret
    eq crypto.exportPublicKey(), publicHex
    do done

  it 'should calculate hash', (done) ->
    crypto = new Crypto
    secret = "e5d885337f78a71b1cf0d2a799c794d79e1874269a4fb34c7661227f9499b94d"
    text = "some text to hash"
    expectedHash = "a439d577131d84ff2f8b53031891154dec930a261ecef80b56b3192b"
    crypto.restoreFromPrivateKey secret
    eq crypto.hash(text, algorithm='sha224').toString('hex'), expectedHash
    do done

  it 'should encrypt and decrypt message', (done) ->
    crypto = new Crypto
    secret = "e5d885337f78a71b1cf0d2a799c794d79e1874269a4fb34c7661227f9499b94d"
    anotherSecret = "a3d6070b6cad77013fd4517824aa2aec892431d2806e29cedd18cebe6d0fd90f"
    pubkey = "02c6a930f244880e3529ab446ad3e6aae2ff2b6ee31fcc84ed21917af5bbb5c208"
    message = "some very long message goes here"
    crypto.restoreFromPrivateKey secret
    encryptedMessage = crypto.encrypt message, pubkey
    anotherCrypto = new Crypto
    anotherCrypto.restoreFromPrivateKey anotherSecret
    eq (anotherCrypto.decrypt encryptedMessage).toString('utf8'), message
    do done
