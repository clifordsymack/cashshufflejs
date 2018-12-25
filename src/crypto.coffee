{ PrivateKey, PublicKey } = require('bitcoincashjs-fork')

crypto = require "crypto"

aesEncryptWithIV = (key, iv, message) ->
  cipher = crypto.createCipheriv 'aes-128-cbc', key, iv
  cipher.setAutoPadding(true)
  crypted = cipher.update message, 'hex', 'hex'
  crypted += cipher.final 'hex'
  Buffer.from(crypted, 'hex')

aesDecryptWithIV = (key, iv, message) ->
  cipher = crypto.createDecipheriv 'aes-128-cbc', key, iv
  cipher.setAutoPadding(true)
  crypted = cipher.update message, 'hex', 'hex'
  crypted += cipher.final 'hex'
  Buffer.from(crypted, 'hex')

class Crypto

  constructor: () ->

  generateKeyPair: () ->
    @privateKey = new PrivateKey

  exportPrivareKey: () ->
    if @privateKey
      @privateKey.toString('hex')
    else
      null

  restoreFromPrivateKey: (secretHex) ->
    try
      @privateKey = new PrivateKey(secretHex)
    catch error
      null

  exportPublicKey: () ->
    @privateKey.publicKey.toString('hex')

  encrypt: (message, pubkey) ->
    publicKey = PublicKey(pubkey)
    ephemeral = new PrivateKey
    secretMultiplier = ephemeral.toBigNumber()
    ecdhKey = PublicKey(publicKey.point.mul(secretMultiplier)).toBuffer()
    key = crypto.createHash('sha512').update(ecdhKey).digest()
    [iv, keyE, keyM] = [key[0..15], key[16..31], key[32..] ]
    ciphertext = aesEncryptWithIV keyE, iv, Buffer.from(message, 'utf8')
    prefix = Buffer.from('BIE1')
    encrypted = Buffer.concat [prefix, ephemeral.publicKey.toBuffer(), ciphertext]
    mac = crypto.createHmac('sha256', keyM).update(encrypted).digest()
    Buffer.concat([encrypted, mac]).toString('base64')

  decrypt: (encryptedMessage) ->
    encrypted = Buffer.from encryptedMessage, 'base64'
    if encrypted.length < 85
      throw "invalid ciphertext: length"
    [magic, ephemeralPubkey, ciphertext, mac] = [
      encrypted[..3]
      encrypted[4..36]
      encrypted[37..-33]
      encrypted[-32..]
      ]
    if magic.toString() != "BIE1"
      throw "invalid ciphertext: invalid magic bytes"
    try
      ephemeralPubkey = PublicKey ephemeralPubkey
    catch error
      throw "invalid ciphertext: invalid ephemeral pubkey"
    ephemeralPubkey.point.validate()
    secretMultiplier = @privateKey.toBigNumber()
    ecdhKey = PublicKey(ephemeralPubkey.point.mul(secretMultiplier)).toBuffer()
    key = crypto.createHash('sha512').update(ecdhKey).digest()
    [iv, keyE, keyM] = [key[0..15], key[16..31], key[32..]]
    if mac.toString('hex') != crypto.createHmac('sha256', keyM).update(encrypted[..-33]).digest('hex')
      throw "invalid password"
    aesDecryptWithIV keyE, iv, ciphertext

  hash: (text, algorithm = 'sha224') ->
    try
      crypto.createHash(algorithm).update(Buffer.from(text), "utf8").digest()
    catch error
      null

module.exports = Crypto
