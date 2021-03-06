https = require 'https'
{ Transaction, Address, Script, crypto, PublicKey, Message } = require 'bitcoincashjs-fork'


blockchairEndpoint = 'https://api.blockchair.com/bitcoin-cash/dashboards/transaction/'

getLegacyAddress = (address) ->
  try
    if address.length == 34
      Address.fromString(address).toString()
    else
      try
        Address.fromString 'bitcoincash:' + address.split(':')[-1..][0],
         'livenet', 'pubkeyhash', Address.CashAddrFormat
        .toString()
      catch ValidationError
        try
          Address.fromString 'bchtest:' + address.split(':')[-1..][0],
           'testnet', 'pubkeyhash', Address.CashAddrFormat
          .toString()
        catch error
          throw error
  catch error
    throw error

getCoin = (pubkey, coin) ->
  new Promise (resolve, reject) ->
    [txHash, txOutput] = coin.split(':')
    request = https.get blockchairEndpoint + txHash, (response) ->
      if response.statusCode < 200 or response.statusCode > 299
        reject new Error 'Failed to get data ' + response.statusCode
      response.on 'data', (data) ->
        try
          output = JSON.parse(data.toString()).data[txHash].outputs[txOutput]
          coinOutput =
            txid: output.transaction_hash
            vout: output.index
            address: getLegacyAddress output.recipient
            script: output.script_hex
            satoshis: output.value
            is_spent: output.is_spent
          resolve [pubkey, coin, coinOutput]
        catch error
          reject error
    request.on 'error', (error) ->
      reject error

getCoins = (inputs) ->
  new Promise (resolve, reject) ->
    promises = []
    for pubkey of inputs
      for coin in inputs[pubkey]
        promises.push getCoin(pubkey, coin)
    Promise.all(promises)
    .then (result) ->
      coins = {}
      coins[pubkey] = {} for [pubkey, coin, output] in result
      coins[pubkey][coin] = output for [pubkey, coin, output] in result
      resolve coins
    .catch (error) ->
      reject error

inputName = (input) -> input.prevTxId.toString('hex')+ ":" + input.outputIndex


class Coin

  constructor: () ->

  getCoins: (inputs) -> getCoins inputs

  checkSufficientFunds: (inputs, amount) ->
    new Promise (resolve, reject) ->
      getCoins inputs
      .then (coins) ->
        isEnoughFunds = []
        for pubkey of coins
          value = [coins[pubkey][coin]['satoshis'] for coin of coins[pubkey]][0]
                  .reduce (x, y) ->
                    x + y
                  , 0
          allNotSpent = [coins[pubkey][coin]['is_spent'] for coin of coins[pubkey]][0]
                        .reduce (x,y) ->
                          x or y
                        , false
          isEnoughFunds.push ( not allNotSpent) and (value > amount)
        result = isEnoughFunds
                 .reduce (x,y) ->
                   x and y
                 , true
        resolve result
      .catch (error) ->
        reject error

  makeUnsignedTransaction: (amount, fee, allInputs, outputs, changes) ->
    new Promise (resolve, reject) ->
      promises = []
      players = []
      txIns = {}
      for player, inputs of allInputs
        players.push player
        promises.push getCoins(inputs)
      Promise.all promises
      .then (result) ->
        utxos = []
        amounts = {}
        for inputs, i in result
          amounts[players[i]] = 0
          for pubkey, coins of inputs
            for coin, output of coins
              txIns[coin] = pubkey
              amounts[players[i]] += output.satoshis
              utxos.push Transaction.UnspentOutput(output)
        utxos.sort (a, b) ->
          if (a.txId + a.outputIndex) > (b.txId + b.outputIndex) then 1 else -1
        txOutputs = ([getLegacyAddress(address), amount] for address in outputs)
        players.sort()
        txChanges = ([changes[player], amounts[player] - amount - fee] for player in players when (amounts[player] - amount - fee) > 0)
        txChanges.sort (a,b) ->
        tx = Transaction()
             .from utxos
        for output in [txOutputs..., txChanges...]
          tx.to getLegacyAddress(output[0]), output[1]
        for input in tx.inputs
          input.sequenceNumber = 0xfffffffe # fix sequence number for EC compatibility
          txIn = inputName input
          input.setScript Script("21" + txIns[txIn])
        resolve tx
      .catch (error) ->
        reject error

  getTransactionSignature: (transaction, inputs, secretKeys) ->
    signatures = {}
    inputsPubkeys =  Object.keys inputs
    for pubkey, privkey of secretKeys when pubkey in inputsPubkeys
      for signature in transaction.getSignatures(privkey)
        txHash = inputName signature
        inputSignature = Buffer.from(signature.signature.toString() + "41", 'utf-8') # nHashType == 65 only for now.
        temp = {}
        temp[txHash] = inputSignature
        Object.assign signatures, temp
    signatures

  addTransactionSignatures: (transaction, signatures) ->
    for input in transaction.inputs
      txIn = inputName input
      pubkey = (input._scriptBuffer.toString 'hex')[2..]
      signature = Buffer.from signatures[txIn].toString('utf-8')[..-2], 'hex'
      input.setScript Script.buildPublicKeyHashIn(pubkey, signature, 0x41)

  verifyTransactionSignature: (signature, transaction, verificationKey, txHash) ->
    inputIndex = transaction
                 .inputs
                 .map inputName
                 .indexOf txHash
    if inputIndex > 0
      signatureCrypto = crypto.Signature.fromTxFormat Buffer.from(signature.toString('utf-8'), 'hex')
      signatureObject =
        signature: signatureCrypto
        publicKey: PublicKey verificationKey
        inputIndex: inputIndex
        sigtype: signatureCrypto.nhashtype
      transaction.inputs[inputIndex].isValidSignature transaction, signatureObject
    else
      false

  verifySignature: (signature, message, verificationKey) ->
    address = PublicKey(verificationKey).toAddress()
    messageBase64 = message.toString 'base64'
    signatureBase64 = signature.toString 'base64'
    Message messageBase64
    .verify address, signatureBase64


module.exports = Coin

# https.get blockchairEndpoint+transactionHash, (res) ->
#
#   res.on 'data', (d) ->
#     data = JSON.parse(d.toString())
#     console.log data.data[transactionHash].outputs[2]
