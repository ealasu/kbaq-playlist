assert = require 'assert'
#process = require 'process'

parser = require '../src/server/parser.coffee'

describe 'parser', ->
  describe 'getPlaylist', ->
    it 'should work', (done) ->
      parser.getPlaylist '04-05-2013', (errors, playlist) ->
        console.log playlist
        done(errors)
