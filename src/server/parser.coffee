_ = require('underscore')
jsdom = require('jsdom')
nodetime = require('time')
moment = require('moment')



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
    text: text



parsePlaylistDom = (selector, callback) ->
  text = selector('#main-content #content div.node-content div.field div.field-items').html()
  if not text
    text = selector('#main-content #content div.node-content section div.field-items').last().html()
  text = text.replace /\s+/ig, ' '
  text = text.replace /(<br\s*\/?>)|(<\/div\s*>\s*<div[^>]*>)|(<div[^>]*>)|(<\/div\s*>)/ig, '\n' # 
  text = text.replace /(<i>)|(<\/i>)|(<b>)|(<\/b>)|(<span[^>]*>)|(<\/span\s*>)/ig, ''
  console.log 'fixed text: ' + text
  lines = text.split('\n')

  firstLineMatcher = /^\s*(\d+:\d+(:\d+)?:?\s*[AP]M)\s*(.*$)/ig

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

getPlaylistUrl = (playlistDate) ->  # 2013-03-13
  #d = moment(playlistDate, 'MMDDYYYY').getDate()
  #nodetime.extend(d)
  #d.setTimezone('US/Arizona')
  'http://www.kbaq.org/content/' + (if playlistDate is 'today' then 'todays-playlist' else 'kbaq-playlist-' + playlistDate)

exports.getPlaylist = getPlaylist = (playlistDate, callback) ->
  url = getPlaylistUrl(playlistDate)
  console.log url
  jsdom.env(
    url, 
    ['http://code.jquery.com/jquery-1.9.1.min.js'],
    (errors, window) ->
      if errors
        console.log 'jsdom.env failed: ' + errors
        callback(errors)
      else
        parsePlaylistDom window.$, (errors, playlist) ->
          callback(errors, playlist)
          window.close()
  )

