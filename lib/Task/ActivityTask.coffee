_ = require "underscore"
Promise = require "bluebird"
Match = require "mtr-match"
stamp = require "../../helper/stamp"
Task = require "../Task"
errors = require "../../helper/errors"

class ActivityTask extends Task
  constructor: (input, options, streams, dependencies) ->
    Match.check input, Match.ObjectIncluding
      commandId: String
    Match.check streams, Match.ObjectIncluding
      in: Match.Where (stream) -> Match.test(stream.read, Function) # stream.Readable or stream.Duplex
      out: Match.Where (stream) -> Match.test(stream.write, Function) # stream.Writable or stream.Duplex
    super(options, dependencies)
    commonKeys = _.intersection(_.keys(input), _.keys(options), _.keys(streams), _.keys(dependencies))
    throw new errors.RuntimeError(
      message: "The keys of `options`, `options.input`, `dependencies` can't overlap"
      explanation: "Most probably, you've defined some keys on `options.input` that already exist either on `options` or `dependencies`"
      response: "Rename conflicting keys in `options.input`"
      commonKeys: commonKeys
    ) if commonKeys.length
    _.extend @, input, streams
    @mongodb = dependencies.mongodb
    Match.check @mongodb, Match.Any

  progressBarSetTotal: (total) -> @mongodb.collection("Commands").update({_id: @commandId, "progressBars.activityId": @activityId}, {$set: {"progressBars.$.total": total}}).then -> total
  progressBarIncCurrent: (inc) -> @mongodb.collection("Commands").update({_id: @commandId, "progressBars.activityId": @activityId}, {$inc: {"progressBars.$.current": inc}}).then -> inc
  # progressBarIncCurrent shouldn't be called for each object, because it will result in a flood of DB writes; instead, progressBarIncCurrent should be called in batches (e.g. for each page)

  execute: -> throw new Error("Implement me!")

  arguments: (parentInput, activityId) ->
    input = stamp parentInput[activityId].input, parentInput
    options = _.omit(parentInput[activityId], "input")
    input: input
    options: _.extend options, activityId: activityId

module.exports = ActivityTask
