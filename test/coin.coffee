assert = require 'assert'
eq = assert.equal

Coin = require '../src/coin.coffee'

{ PrivateKey, Transaction } = require 'bitcoincashjs-fork'

class FakeBlockchain
  @_blockchain: {}

  @addCoins: (coins) ->
    Object.assign @_blockchain, coins

  @getCoins: (inputs) ->
    new Promise (resolve, reject) ->
      coins = {}
      for pubkey of inputs
        coins[pubkey] = {}
        for coin in inputs[pubkey]
          try
            coins[pubkey][coin] = [ pubkey, coin, FakeBlockchain._blockchain[coin]]
          catch error
            reject error
      resolve coins


describe "Coin", ->

  it 'should create Coin', (done) ->
    coin = new Coin
    assert.ok coin isnt null
    do done

  it 'should get coins from blockchain', (done) ->
    coin = new Coin
    inputs =
      "038ed3556b5d862850eaa8a5558661a9e26b35dbec5a5df9d39c998f377309d334" : [
        "7b4ca61bea9882d04e183f93cbbf60392f1e544b5239032247a3b4c18961337c:1"
        ]
      "023af6269bc997fbb8d0ef62174a0dbf596103bb636f6566e6bbe6559e12b0fa99": [
        "325b4249756e2fdd1764468fe3c83ae3153952290159d6f2a26a405f72c42dbb:4"
        "7b4ca61bea9882d04e183f93cbbf60392f1e544b5239032247a3b4c18961337c:4"
        "34ec2d22d2aec9beb3ed98beb3174dd1f5266d7947aea41c0d2317460a16c2d9:5"
      ]
    coin.getCoins(inputs)
    .then (result) ->
      for pubkey of inputs
        assert.ok result[pubkey] isnt null
        for coin in inputs[pubkey]
          assert.ok result[pubkey][coin] isnt null
    .catch (error) ->
      console.log error
    do done

  it 'should check for sufficient funds', (done) ->
    coin = new Coin
    inputs =
      "038ed3556b5d862850eaa8a5558661a9e26b35dbec5a5df9d39c998f377309d334" : [
        "7b4ca61bea9882d04e183f93cbbf60392f1e544b5239032247a3b4c18961337c:1"
        ]
      "023af6269bc997fbb8d0ef62174a0dbf596103bb636f6566e6bbe6559e12b0fa99": [
        "325b4249756e2fdd1764468fe3c83ae3153952290159d6f2a26a405f72c42dbb:4"
        "7b4ca61bea9882d04e183f93cbbf60392f1e544b5239032247a3b4c18961337c:4"
        "34ec2d22d2aec9beb3ed98beb3174dd1f5266d7947aea41c0d2317460a16c2d9:5"
      ]
    coin.checkSufficientFunds(inputs, 1000)
    .then (result) ->
      assert.ok result
    .catch (error) ->
      console.log error
    do done

  it 'should make unsigned transaction', (done) ->
    coin = new Coin
    FakeBlockchain.addCoins {
      "a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721:2":
        txId: 'a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721'
        outputIndex: 2
        address: '19GSh5YLTZeExwcgJy6dhVxt43aE6vuxd2'
        script: '76a9145aacb1040a3c8e67ad7f1205001d2f08c6cb784d88ac'
        satoshis: 4000
        is_spent: true
      'd5fa351d731f4c8248beed455663afe0a8b7e4c69180e8e9bda2e9d9ef876493:2':
        txId: 'd5fa351d731f4c8248beed455663afe0a8b7e4c69180e8e9bda2e9d9ef876493'
        outputIndex: 2
        address: '12FyjDmqAsyyM9UPzzx6r4XR8rAELc7b85'
        script: '76a9140dcd4da7f6007c2d9f988fe3001a6561c6297ce388ac'
        satoshis: 98000
        is_spent: true
      '43987285aa84d576878cad3a33bbb46aec4fdbb21dab3a105e7e6b4c577e271d:4':
        txId: '43987285aa84d576878cad3a33bbb46aec4fdbb21dab3a105e7e6b4c577e271d'
        outputIndex: 4
        address: '13dCAf7VQ78eBhJhYTmEy3G9bqwt3VpH2J'
        script: '76a9141cc88c2a274e1f434cf72e04c42e6ab2db853e4f88ac'
        satoshis: 4500
        is_spent: true
    }
    coin.getCoins = (inputs) -> FakeBlockchain.getCoins(inputs)
    inputs =
      "player_vk_1":
        '0236ceb580e9613ff718f17f3f1294508c68decf848b23cca7c75c2ed49ec69601':
          ["a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721:2"]
      "player_vk_2":
        "029b8a2373a5ba52817527e092be091fdbac499cf160d048d1966161a1fec30842":
          ["d5fa351d731f4c8248beed455663afe0a8b7e4c69180e8e9bda2e9d9ef876493:2"]
      "player_vk_3":
        "02ecd2a2911b1099daedc950dc03e9ee867969c8aec06d464a0c144427aa99cf13":
          ["43987285aa84d576878cad3a33bbb46aec4fdbb21dab3a105e7e6b4c577e271d:4"]
    outputs = [
      "qzuqmss357hfux4d9gxg68yxgh2rtzc9xq020lzw0m"
      "qrwr23lu7x072ztsjcvsqyjkdsn7cvvjeuac7hrz03"
      "qzkffzh8uyvmq0qf0qer6g7a4azjfdg98u28cf4amv"
    ]
    changes =
      "player_vk_1": "qqwv3rp2ya8p7s6v7uhqf3pwd2edhpf7fuhhq25del"
      "player_vk_2": "qpd2evgypg7guead0ufq2qqa9uyvdjmcf59k4kkwgk"
      "player_vk_3": "qqxu6nd87cq8ctvlnz87xqq6v4suv2tuuvyyvre3x8"
    coin.makeUnsignedTransaction 1000, 300, inputs, outputs, changes
    .then (tx) ->
      eq tx.constructor.name, "Transaction"
      # more tests should be here
    .catch (error) ->
      console.log(error)
    do done

  it 'should get transaction signatures', (done) ->
    FakeBlockchain.addCoins {
      "a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721:2":
        txId: 'a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721'
        outputIndex: 2
        address: '19GSh5YLTZeExwcgJy6dhVxt43aE6vuxd2'
        script: '76a9145aacb1040a3c8e67ad7f1205001d2f08c6cb784d88ac'
        satoshis: 4000
        is_spent: true
      'd5fa351d731f4c8248beed455663afe0a8b7e4c69180e8e9bda2e9d9ef876493:2':
        txId: 'd5fa351d731f4c8248beed455663afe0a8b7e4c69180e8e9bda2e9d9ef876493'
        outputIndex: 2
        address: '12FyjDmqAsyyM9UPzzx6r4XR8rAELc7b85'
        script: '76a9140dcd4da7f6007c2d9f988fe3001a6561c6297ce388ac'
        satoshis: 98000
        is_spent: true
      '43987285aa84d576878cad3a33bbb46aec4fdbb21dab3a105e7e6b4c577e271d:4':
        txId: '43987285aa84d576878cad3a33bbb46aec4fdbb21dab3a105e7e6b4c577e271d'
        outputIndex: 4
        address: '13dCAf7VQ78eBhJhYTmEy3G9bqwt3VpH2J'
        script: '76a9141cc88c2a274e1f434cf72e04c42e6ab2db853e4f88ac'
        satoshis: 4500
        is_spent: true
    }
    coin = new Coin
    coin.getCoins = (inputs) -> FakeBlockchain.getCoins(inputs)
    inputs =
      "player_vk_1":
        '0236ceb580e9613ff718f17f3f1294508c68decf848b23cca7c75c2ed49ec69601':
          ["a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721:2"]
      "player_vk_2":
        "029b8a2373a5ba52817527e092be091fdbac499cf160d048d1966161a1fec30842":
          ["d5fa351d731f4c8248beed455663afe0a8b7e4c69180e8e9bda2e9d9ef876493:2"]
      "player_vk_3":
        "02ecd2a2911b1099daedc950dc03e9ee867969c8aec06d464a0c144427aa99cf13":
          ["43987285aa84d576878cad3a33bbb46aec4fdbb21dab3a105e7e6b4c577e271d:4"]
    outputs = [
      "qzuqmss357hfux4d9gxg68yxgh2rtzc9xq020lzw0m"
      "qrwr23lu7x072ztsjcvsqyjkdsn7cvvjeuac7hrz03"
      "qzkffzh8uyvmq0qf0qer6g7a4azjfdg98u28cf4amv"
    ]
    changes =
      "player_vk_1": "qqwv3rp2ya8p7s6v7uhqf3pwd2edhpf7fuhhq25del"
      "player_vk_2": "qpd2evgypg7guead0ufq2qqa9uyvdjmcf59k4kkwgk"
      "player_vk_3": "qqxu6nd87cq8ctvlnz87xqq6v4suv2tuuvyyvre3x8"
    secretKeys =
      '0236ceb580e9613ff718f17f3f1294508c68decf848b23cca7c75c2ed49ec69601': PrivateKey "L14e78QaSvDFxbQ3LzmSB9dAEc5ovWKWRKS8M7GRK7SNCahcsK5G",
    coin.makeUnsignedTransaction 1000, 300, inputs, outputs, changes
    .then (tx) ->
      signatures = coin.getTransactionSignature tx, inputs['player_vk_1'], secretKeys
      assert.deepEqual signatures['a2e85c628edb9ab4b29e55b17f69ab2af652e186ec38eb650381e87c370a7721:2'] , Buffer.from("304402204167fa3ac782d5df521bc67eb28c4a70b1087a77dbe623971b13d1cd781b358d02204ef68fbc7e2a188c4065e72809bfb1638c118ad8d5e495e921085d5e7d77aa4141", 'utf-8')
    .catch (error) ->
      console.log(error)
    do done
