###
Wraps around a socket connection, providing an ID to identify it by.
###
module.exports = class SocketClient

  constructor: (@socket) ->
    @id = uuid.v4()


  # Sends data to this client via it's socket connection.
  # Will be encoded as JSON if not already a string.
  send: (data, done) ->
    if typeof data isnt 'string' then data = JSON.stringify(data)

    if @socket?.readyState is ws.OPEN
      @socket.send data, Log.ErrorHandler

    done()
