process.env.TZ = 'UTC'

express = require 'express'
request = require 'request'
jsdom = require 'jsdom'
_ = require 'underscore'
path = require 'path'
http = require 'http'
nodetime = require 'time'
moment = require 'moment'
parser = require './parser'

if process.env.REDISTOGO_URL
  console.log 'Redis url: %s', process.env.REDISTOGO_URL
  rtg   = require("url").parse(process.env.REDISTOGO_URL)
  redis = require("redis").createClient(rtg.port, rtg.hostname)
  redis.auth rtg.auth.split(":")[1]
else 
  redis = require("redis").createClient()


getCachedPlaylist = (playlistDate, callback) ->
  cacheKey = playlistDate
  redis.get cacheKey, (err, reply) ->
    if err
      callback err
    else if reply
      console.log 'cache hit for %s', cacheKey
      callback null, JSON.parse(reply)
    else
      console.log 'cache miss for %s', cacheKey
      parser.getPlaylist playlistDate, (errors, playlist) ->
        if errors
          console.log 'getPlaylist failed: ' + errors
          callback errors
        else
          redis.set cacheKey, JSON.stringify(playlist)
          callback null, playlist


getTodaysDateString = () ->
  now = new nodetime.Date()
  now.setTimezone('America/Phoenix')
  return moment(now).format('YYYY-MM-DD')


app = express()

app.configure () ->
  app.set 'port', process.env.PORT || 5000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.logger('dev')
  app.use express.static(path.join(__dirname, '../client'))

handlePlaylistRequest = (playlistDate, req, res) ->
  getCachedPlaylist playlistDate, (errors, playlist) ->
    if errors
      console.log 'getCachedPlaylist failed: ' + errors
      res.send(500)
    else
      res.send(playlist)

app.get '/playlist/today', (req, res) ->
  handlePlaylistRequest getTodaysDateString(), req, res

app.get '/playlist/:date', (req, res) ->
  handlePlaylistRequest req.params.date, req, res


http.createServer(app).listen app.get('port'), () ->
  console.log "Listening on " + app.get('port')

