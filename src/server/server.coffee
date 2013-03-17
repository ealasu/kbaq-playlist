express = require('express')
request = require('request')
jsdom = require('jsdom')
_ = require('underscore')
path = require('path')
http = require('http')
nodetime = require('time')
moment = require('moment')

process.env.TZ = 'UTC'

if process.env.REDISTOGO_URL
  console.log 'Redis url: %s', process.env.REDISTOGO_URL
  rtg   = require("url").parse(process.env.REDISTOGO_URL)
  redis = require("redis").createClient(rtg.port, rtg.hostname)
  redis.auth rtg.auth.split(":")[1]
else 
  redis = require("redis").createClient()


_.mixin {
  partitionBy: (obj, val) ->
    last = []
    result = [last]
    lastVal = null
    _.each obj, (value, index) ->
      currentVal = val(value)
      if currentVal != lastVal && index > 0
        last = []
        result.push(last)
      lastVal = currentVal
      last.push(value)
    result
  }

parseAlbum = (text) ->
  match = /(.*?)\s*(\d+)/g.exec(text)
  if match != null
    label: match[1],
    catalog: match[2]
  else
    name: text



parsePlaylist = (selector, callback) ->
  text = selector('p').text()
  lines = text.split('\n')
  playlistDate = /Playlist for (.+?)\s*$/g.exec(selector('h4').first().text())[1]
  console.log 'playlist date: ' + playlistDate

  firstLineMatcher = /^\s*(\d+:\d+(:\d+)?:?\s*[AP]M)\s*(.*$)/i

  tracks = _.chain(lines)
    .reject((line) -> line.match(/\s*\d+\s*\|\s*\d+\s*/g))  # ignore last line
    .partitionBy((line) -> line.match(/^[\s_]*$/))          # partition by blank lines
    .reject((group) -> _.any(group, (line) -> line.match(/^[\s_]*$/))) # ignore blank lines
    .filter((group) -> group[0].match(firstLineMatcher))    # ignore groups that don't start with a track time
    .map((group) ->
      _.map group, (line) ->
        line.trim().replace(/\s*-$/, '')) # remove trailing whitespace and dashes
    .map((group) ->
      firstLine = group[0]
      group = _.rest(group)
      match = firstLine.match(firstLineMatcher)
      if (match)
        time = match[1]
        name = match[3].trim()
        if (!name)
          name = group[0]
          group = _.rest(group)
        {
          'time': time,
          'name': name,
          'artists': _.initial(group),
          'album': parseAlbum(_.last(group))
        }
      else
        console.log 'ERROR: failed match on time line, ' + firstLine + '\n' + group)
    .value()

  if _.size(tracks) == 0
    callback 'no tracks'
  else
    callback null,
      tracks:
        tracks


getPlaylistUrl = (playlistDate) ->
  return 'http://kbaq.org/music/playlists/text?' + playlistDate + '_playlist.txt';

getPlaylist = (playlistDate, callback) ->
  #d = moment(playlistDate, 'MMDDYYYY').getDate()
  #nodetime.extend(d)
  #d.setTimezone('US/Arizona')
  jsdom.env(
    getPlaylistUrl(playlistDate), 
    ['http://code.jquery.com/jquery-1.5.min.js'],
    (errors, window) ->
      if errors
        console.log 'jsdom.env failed: ' + errors
        callback(errors)
      else
        parsePlaylist window.$, (errors, playlist) ->
          callback(errors, playlist)
          window.close()
  )

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
      getPlaylist playlistDate, (errors, playlist) ->
        if errors
          console.log 'getPlaylist failed: ' + errors
          callback errors
        else
          redis.set cacheKey, JSON.stringify(playlist)
          callback null, playlist


getTodaysDateString = () ->
  now = new nodetime.Date()
  now.setTimezone('America/Phoenix')
  return moment(now).format('MMDDYYYY')


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


