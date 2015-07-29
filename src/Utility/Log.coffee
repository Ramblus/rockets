###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  @ErrorHandler: (error) ->
    if error then log.error {
      error: error,
      stack: error.stack
    }


  constructor: () ->

    @loggers =
      info: bunyan.createLogger({
        name: 'rockets',
        streams: [
          {
            level: 'info',
            stream: process.stdout,
          },
        ]
      })

      error: bunyan.createLogger({
        name: 'rockets',
        streams: [
          {
            level: 'error',
            stream: process.stderr,
          },
        ]
      })


  # Log arbitrary arguments to the info log
  info: () ->
    @loggers.info.info arguments


  # Log arbitrary arguments to the error log
  error: () ->
    @loggers.error.error arguments
