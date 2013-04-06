assert = require 'assert'
#process = require 'process'

parser = require '../src/server/parser.coffee'

describe 'parser', ->
  describe 'getPlaylist', ->
    it 'should work for archived playlists', (done) ->
      parser.getPlaylist '04-05-2013', (errors, playlist) ->
        #console.log playlist
        done(errors)
    it "should work for today's playlist", (done) ->
      parser.getPlaylist 'today', (errors, playlist) ->
        console.log playlist
        done(errors)
