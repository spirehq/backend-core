helpers = require "../helpers"
_ = require "underscore"
stream = require "readable-stream"
Echo = require "../Echo"

describe "Echo", ->
  echo = null;

  beforeEach ->
    echo = new Echo(
      input: new stream.Readable({objectMode: true})
      output: new stream.Writable({objectMode: true})
    )

  describe "error handling", ->

    it "should stop reading off input if it throws an exception", ->
      echo.input._read = ->
        @push "Schmetterling!"
        @push "Not read"
        @push null
      echo.output._write = sinon.spy()
      echo.execute()
      .then ->
        echo.output._write.should.have.not.been.called