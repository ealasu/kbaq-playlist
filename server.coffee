express = require('express')
request = require('request')
jsdom = require('jsdom')
_ = require('underscore')
require('datejs')
path = require('path')
http = require('http')


if process.env.REDISTOGO_URL
  console.log 'Redis url: %s', process.env.REDISTOGO_URL
  rtg   = require("url").parse(process.env.REDISTOGO_URL)
  redis = require("redis").createClient(rtg.port, rtg.hostname)
  redis.auth rtg.auth.split(":")[1]
else 
  redis = require("redis").createClient()


default_date = Date.today()

partitionBy = (obj, val) ->
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


parsePlaylist = (selector) ->
  text = selector('p').text()
  lines = text.split('\n')
  playlistDate = new Date(/Playlist for (.+?)\s*$/g.exec(selector('h4').first().text())[1])
  console.log(playlistDate)

  result = lines
  result = _.filter(result, (val) -> !val.match(/\s*\d+\s*\|\s*\d+\s*/g))
  result = partitionBy(result, (val) -> val.match(/^[\s_]*$/))
  result = _.filter(result, (val) -> !_.any(val, (v2) -> v2.match(/^[\s_]*$/)))
  result = _.filter(result, (val) -> val[0].match(/^\s*\d+:\d+.*$/))
  result = _.map(result, (val) ->
    return _.map(val, (val2) ->
      return val2.trim() ))
  result = _.map(result, (val) ->
    first = val[0].match(/^\s*(\d+:\d+\s*[AP]M)\s*(.+$)/i)
    if (first)
      playTime = Date.parse(playlistDate.toString('M/d/yyyy') + ' ' + first[1])
      playTime.setTimezone('MST')
      {
        'time': playTime.getTime(),
        'name': first[2],
        'artists': _.initial(_.rest(val)),
        'album': _.last(val)
      }
  )
  result

getPlaylistUrl = (playlistDate) ->
  console.log 'Today: %s', new Date().toString()
  console.log 'Requested date: %s', playlistDate
  console.log 'Requested date to string: %s', playlistDate.toString('MMddyyyy')
  return 'http://kbaq.org/music/playlists/text?' + playlistDate.toString('MMddyyyy') + '_playlist.txt';

getPlaylist = (playlistDate, callback) ->
  playlistDate.setTimezone('MST')
  jsdom.env(
    getPlaylistUrl(playlistDate), 
    ['http://code.jquery.com/jquery-1.5.min.js'],
    (errors, window) ->
      callback(parsePlaylist(window.$))
      window.close()
  )

getCachedPlaylist = (playlistDate, callback) ->
  cacheKey = playlistDate.toString('MMddyyyy')
  redis.get cacheKey, (err, reply) ->
    if reply
      console.log 'cache hit for %s', cacheKey
      callback JSON.parse(reply)
    else
      console.log 'cache miss for %s', cacheKey
      getPlaylist playlistDate, (playlist) ->
        redis.set cacheKey, JSON.stringify(playlist)
        callback playlist


#app = express.createServer(express.logger())
app = express()

app.configure () ->
  app.set 'port', process.env.PORT || 5000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.logger('dev')
  app.use express.static(path.join(__dirname, 'public'))


app.get '/', (req, res) ->
  getCachedPlaylist new Date(), (playlist) ->
    res.render 'index', {
      'title': "Today's playlist", 
      'playlist': playlist
    }


app.get '/playlist/:date', (req, res) ->
  getCachedPlaylist Date.parse(req.params.date), (playlist) ->
    res.send(playlist)



http.createServer(app).listen app.get('port'), () ->
  console.log "Listening on " + app.get('port')


