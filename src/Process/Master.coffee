###
Master process, responsible for:
  - Forking socket server workers
  - Initiating request tasks
###
module.exports = class Master

  constructor: () ->
    @fork()
    @run()


  # Fork workers, which will each create a `Worker` process.
  fork: () ->
    cluster.on 'fork', @registerWorkerEvents.bind(@)
    cluster.fork() for _ in [0...(os.cpus().length-1)]


  # Registers events on a new cluster worker
  registerWorkerEvents: (worker) ->
    worker.on 'error', Log.ErrorHandler

    # Called when a worker process is started
    worker.on 'online', ->
      log.info {
        event: 'worker.online',
        id: worker.id
      }

    # Fork a new worker when this one dies
    worker.on 'disconnect', ->
      cluster.fork()

    # Might be good to know why a worker died
    worker.on 'exit', (code, signal) ->
      log.info {
        event: 'worker.exit',
        code: code,
        signal: signal,
        id: worker.id,
      }


  # Returns an array of model fetch tasks to run
  run: () ->
    process.started = Date.now() / 1000

    oauth = new OAuth2()
    queue = new ModelQueue()

    comments = new CommentTask(oauth, queue)
    posts    = new PostTask(oauth, queue)

    # This will be the task schedule to keep iterating through.
    tasks = []

    for _ in [0...30]
      tasks.push comments.reversed()
      tasks.push posts.forward()

    tasks.push posts.reversed()

    # Run all tasks in series, forever.
    async.forever (next) ->
      async.series tasks, next
