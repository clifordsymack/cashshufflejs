assert = require 'assert'
eq = assert.equal
{ spawn, spawnSync } = require 'child_process'

Comms = require '../src/comms.coffee'


describe "Comms", ->

  server = null

  before () ->
    server = spawn "cashshuffle", ["-s", "3"]

    server.on 'error', (error) ->
      console.warn "WARNING: NO CASHSHUFFLE SERVER"
      server = null

  after () ->
    if server
      server.kill()

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
    if not server
      do @skip
    comms = new Comms("http://localhost:8080")
    comms.checkProtocol()
    comms.getStats()
    .then (res) ->
      console.log res
    .catch (err) ->
      console.log err
    do done
