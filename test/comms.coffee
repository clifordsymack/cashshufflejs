assert = require 'assert'
eq = assert.equal
{ spawn, spawnSync } = require 'child_process'

Comms = require '../src/comms.coffee'


describe "Comms", ->

  # server = null
  # serverRunning = null
  #
  # before (done) ->
  #   # How to wait for server is running here?
  #
  #   server = spawn "cashshuffle", ["-s", "3"]
  #
  #   server.stdout.on 'data' , (data) ->
  #     # console.log "[CS_SERVER_DATA]:" + data
  #     str = data.toString()
  #     if 'Shuffle Listening via Websockets on :1338' in str.split('\n')
  #       serverRunning = true
  #       do done
  #
  #   server.stderr.on 'data' , (data) ->
  #     console.log "[CS_SERVER_ERROR]:" + data
  #     do done
  #
  #   server.on 'error', (error) ->
  #     console.warn "WARNING: NO CASHSHUFFLE SERVER"
  #     server = null
  #
  #   # return server
  #
  #
  # after () ->
  #   if server
  #     server.kill()

  it 'should make comms object', (done) ->
    comms = new Comms('http://localhost:8080')
    comms.checkProtocol()
    assert.ok not comms.ssl
    comms = new Comms('https://localhost:8080')
    comms.checkProtocol()
    assert.ok comms.ssl
    try
      comms = new Comms('habracadabra://localhost:8080')
    catch error
      eq error.message, "bad cashshuffle server path"
    do done

  it 'should get a ws stats info', (done) ->
    comms = new Comms("http://localhost:8080")
    comms.checkProtocol()
    comms.getStats()
    .then (res) ->
      keys = Object.keys res
      assert.ok "connections" in keys
      assert.ok "poolSize" in keys
      assert.ok "pools" in keys
      assert.ok "shufflePort" in keys
      assert.ok "shuffleWebSocketPort" in keys
    .catch (err) ->
      console.log err
    do done

  it 'should setup websocket server', (done) ->
    comms = new Comms("http://localhost:8080")
    comms.checkProtocol()
    comms.setupWebsocket()
    .then (res) ->
      assert.ok comms.wsPort isnt undefined
    .catch (err) ->
      console.log err
    do done

  it 'should make websocket connection and process messages', (done) ->
    hi_msg = new Buffer.from("0a120a101a090a07736f6d656b65793a0308e807", "hex");
    comms = new Comms("http://localhost:8080")
    comms.checkProtocol()
    comms.setupWebsocket()
    .then (result) ->
      comms.makeConnection hi_msg
    .then (result) ->
      assert.ok true
      new Promise (resolve) ->
        setTimeout(resolve, 10)
    .then (result) ->
      comms.wsClient.close()
    .catch (error) ->
      console.log error
      assert.ok false
    do done

  it 'should provide queue object for subscribing to incomes', (done) ->
    hi_msg = new Buffer.from("0a120a101a090a07736f6d656b65793a0308e807", "hex");
    comms = new Comms("http://localhost:8080")
    comms.result.on "success", (result, job) ->
      assert.ok true
    # console.log comms.result
    comms.checkProtocol()
    comms.setupWebsocket()
    .then (result) ->
      comms.makeConnection hi_msg
    .then (result) ->
      new Promise (resolve) ->
        setTimeout(resolve, 100)
    .then (result) ->
      comms.wsClient.close()
      comms.result.start (err) ->
        if err
          throw err
    .catch (error) ->
      console.log error
      assert.ok false
    do done
