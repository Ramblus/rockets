###
Socket server, responsible for:
  - Keeping track of client channels using a ChannelRepository
  - Listening for new connections
  - Listening for dropped connections
###
module.exports = class SocketServer

  constructor: () ->
    @channels = new ChannelRepository()


  # Starts the server and listens for new connections
  listen: (options) ->
    @server = new ws.Server options

    # Called when a new client has connected.
    @server.on 'connection', (socket) =>
      @onConnect(socket)


  # Returns this server's channels.
  getChannels: () ->
    return @channels


  # Called when a new client has connected.
  onConnect: (socket) ->
    client = new SocketClient(socket)

    log.info {
      event: 'connect',
      client: client.id,
    }

    # Called when an incoming message is received
    socket.on 'message', (message) =>
      @onMessage(message, client)

    # Called when the connection to a client is lost.
    socket.on 'close', () =>
      @onDisconnect(client)

    socket.on 'error', Log.ErrorHandler


  # Called when the connection to a client is lost.
  onDisconnect: (client) ->
    @channels.removeClient(client)

    log.info {
      event: 'disconnect',
      client: client.id,
    }


  # Determines parameters for a subscription's channel and filter values.
  getSubscriptionParameters: (data, callback) ->
    channel = @channels.createChannel(data.channel)

    switch data.channel
      when Channel.POSTS    then filters = new PostFilter(data.filters)
      when Channel.COMMENTS then filters = new CommentFilter(data.filters)

    callback {channel, filters}


  # Attempts to parse a message to determine the channel and channel filters.
  parseMessage: (message, callback) ->
    try
      data = JSON.parse(message)
    catch error
      return Log.ErrorHandler(error)

    if data.channel in [Channel.POSTS, Channel.COMMENTS]
      @getSubscriptionParameters(data, callback)
    else
      callback()


  # Called when an incoming message is received.
  onMessage: (message, client) ->

    log.info {
      event: 'message',
      message: message,
      client: client.id,
    }

    @parseMessage message, (data) ->
      if data
        channel = data.channel
        filters = data.filters

        channel.addSubscription(new Subscription(client, filters))
