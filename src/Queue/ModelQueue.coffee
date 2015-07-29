###
Queue which is responsible for:
  - Sending models to worker processes.
###
module.exports = class ModelQueue extends Queue

  # Send a model to each worker.
  process: (model, next) ->

    # Exclude deleted models entirely.
    if model.data.author.toLowerCase() in ['[deleted]', '[removed]']
      return next()

    switch model.kind
      when 't1' then channel = 'comments'
      when 't3' then channel = 'posts'

    if channel
      for id, worker of cluster.workers
        worker.send {channel, model}

    next()
