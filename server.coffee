express = require('express')
request = require('request')
jsdom = require('jsdom')
_ = require('underscore')
path = require('path')
http = require('http')


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


parsePlaylist = (selector) ->
  text = selector('p').text()
  lines = text.split('\n')
  playlistDate = /Playlist for (.+?)\s*$/g.exec(selector('h4').first().text())[1]
  console.log 'playlist date: ' + playlistDate

  tracks = _.chain(lines)
    .reject((line) -> line.match(/\s*\d+\s*\|\s*\d+\s*/g))  # ignore last line
    .partitionBy((line) -> line.match(/^[\s_]*$/))          # partition by blank lines
    .reject((group) -> _.any(group, (line) -> line.match(/^[\s_]*$/))) # ignore blank lines
    .filter((group) -> group[0].match(/^\s*\d+:\d+.*$/))    # ignore groups that don't start with a track time
    .map((group) ->
      _.map group, (line) ->
        line.trim().replace(/\s*-$/, ''))
    .map((group) ->
      match = group[0].match(/^\s*(\d+:\d+\s*[AP]M)\s*(.*$)/i)
      group = _.rest(group)
      if (match)
        time = match[1]
        name = match[2].trim()
        if (!name)
          name = group[0]
          group = _.rest(group)
        {
          'time': time,
          'name': name,
          'artists': _.initial(group),
          'album': _.last(group)
        }
      else
        console.log 'ERROR: failed match on time line, ' + group + '\n' + lines)
    .value()
  {
    tracks: tracks
  }

getPlaylistUrl = (playlistDate) ->
  return 'http://kbaq.org/music/playlists/text?' + playlistDate + '_playlist.txt';

getPlaylist = (playlistDate, callback) ->
  jsdom.env(
    getPlaylistUrl(playlistDate), 
    ['http://code.jquery.com/jquery-1.5.min.js'],
    (errors, window) ->
      callback(parsePlaylist(window.$))
      window.close()
  )

getCachedPlaylist = (playlistDate, callback) ->
  cacheKey = playlistDate
  redis.get cacheKey, (err, reply) ->
    if reply
      console.log 'cache hit for %s', cacheKey
      callback JSON.parse(reply)
    else
      console.log 'cache miss for %s', cacheKey
      getPlaylist playlistDate, (playlist) ->
        redis.set cacheKey, JSON.stringify(playlist)
        callback playlist


app = express()

app.configure () ->
  app.set 'port', process.env.PORT || 5000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.logger('dev')
  app.use express.static(path.join(__dirname, 'public'))

app.get '/playlist/:date', (req, res) ->
  getCachedPlaylist req.params.date, (playlist) ->
    res.send(playlist)

http.createServer(app).listen app.get('port'), () ->
  console.log "Listening on " + app.get('port')


