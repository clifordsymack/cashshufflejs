url = require "url"
http = require "http"
https = require "https"
WebSocket = require "ws"
queue = require "queue"
# Получение от сервера инфы
# Если данные, то брать их и класть в очередь
# Если отправка, запаковывать и отправлять

magic = Buffer.from "42bcc32669467873", "hex"

class Comms

  constructor: (@path) ->
    @incomeBuffer = Buffer.alloc 0
    @result = queue()
    @inchan = []

  checkProtocol: () ->
    protocol = url.parse(@path).protocol
    @ssl = null
    if protocol=="http:"
      @ssl = false
    if protocol=="https:"
      @ssl = true
    if @ssl is null
      throw new Error("bad cashshuffle server path")

  getStats: () ->
    ssl = @ssl
    path = @path
    new Promise (resolve, reject) ->
      client = if ssl then https else http
      client.get url.resolve(path, "/stats"), (res) ->

        if res.statusCode != 200
          resolve new Error("no stats endpoint on server")

        rawData = ""
        res.on "data", (chunk) ->
          rawData += chunk.toString()
        res.on "end", () ->
          resolve JSON.parse(rawData)
      .on "error", (error) ->
        reject error

  setupWebsocket: () ->
    @getStats()
    .then (res) => # using this type of arrow => instead of -> allows you to modify the class context
      @wsPort = res.shuffleWebSocketPort
    .catch (error) ->
      throw error

  parseMessage: () ->
    while @incomeBuffer.length > 12
      if @incomeBuffer[...8].toString('hex') != magic.toString('hex')
        throw new Error("bad magic word")
      messageLength = @incomeBuffer[8...12].readUInt32BE()
      if @incomeBuffer[12...].length >= messageLength
        @incomeBuffer = @incomeBuffer[12...]
        @result.push (cb) =>
          @inchan.push @incomeBuffer[...messageLength]
          cb()
        @incomeBuffer = @incomeBuffer[messageLength...]
      else
        break

  send: (message) ->
    lengthSuffix = Buffer.alloc 4
    lengthSuffix.writeUIntBE message.length, 0, 4
    try
      @wsClient.send Buffer.concat [magic, lengthSuffix, message]
    catch error
      new Error("unable to send to socket")
    console.log lengthSuffix

  makeConnection: (greetingMessage) ->
    new Promise (resolve, reject) =>
      { hostname, protocol }  = url.parse(@path)
      wsProtocol = if @ssl then "wss:" else "ws:"
      wsPath = wsProtocol+ "//"+ hostname + ":" + @wsPort + "/"
      origin = protocol + "//" + hostname + ":" + @wsPort + "/"
      @wsClient = new WebSocket(wsPath , {origin: origin})

      @wsClient.on 'open', () =>
        @send greetingMessage
        resolve true

      @wsClient.on 'message', (msg) =>
        @incomeBuffer = Buffer.concat([@incomeBuffer, msg])
        @parseMessage()

      @wsClient.on 'error', (error) =>
        reject error


module.exports = Comms
