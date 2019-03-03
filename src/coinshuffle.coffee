class Round

  constructor: () ->
    @coin = null
    @messages = null
    @crypto = null
    @inchan = null
    @outchan = null
    @logchan = null

  setUpMisc: (@coin, @messages, @crypto) ->

  setUpChannels: (@inchan, @outchan, @logchan) ->

module.exports = Round
