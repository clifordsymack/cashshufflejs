url = require "url"
http = require "http"
https = require "https"
# Инициализировать класс
# Выбрать клиент в зависимости от пути
# Получение от сервера инфы
# Если данные, то брать их и класть в очередь
# Если отправка, запаковывать и отправлять

class Comms

  constructor: (@path) ->

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


module.exports = Comms
