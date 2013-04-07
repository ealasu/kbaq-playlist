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



parsePlaylistDom = (selector) ->
  console.log selector('html').html()
  text = selector('#main-content #content div.node-content div.field div.field-items').html()
  if not text
    text = selector('#main-content #content div.node-content section div.field-items').last().html()
  text = text.replace /\s+/ig, ' '
  text = text.replace /(<br\s*\/?>)|(<\/div\s*>\s*<div[^>]*>)|(<div[^>]*>)|(<\/div\s*>)|(<p[^>]*>)|(<\/p\s*>)/ig, '\n' # 
  inline_tags = ['i', 'b', 'strong', 'em', 'span', 'a']
  for t in inline_tags
    text = text.replace(new RegExp("(<#{t}[^>]*>)|(</#{t}[^>]*>)", 'ig'), '')
  #console.log 'fixed text: ' + text
  lines = text.split('\n')

  firstLineMatcher = /^\s*(\d+:\d+(:\d+)?:?\s*[AP]M)\s*(.*$)/ig

  tracks = _.chain(lines)
    .map((line) -> selector('<span/>').html(line).text()) # convert html to text, takes care of escaped chars, etc.
    .reject((line) -> line.match(/\s*\d+\s*\|\s*\d+\s*/g))  # ignore last line
    .map((line) -> line.replace(/[\s-]*$/, '').replace(/^\s*/, '')) # remove padding and trailing dashes
    .partitionBy((line) -> line.match(/^[\s_]*$/))          # partition by blank lines
    .reject((group) -> _.any(group, (line) -> line.match(/^[\s_]*$/))) # ignore blank lines
    .filter((group) -> group[0].match(firstLineMatcher))    # ignore groups that don't start with a track time
    .map((group) ->
      console.log group
      [time, name, artists..., album] = group
      {
        'time': time,
        'name': name.trim(),
        'artists': artists,
        'album': parseAlbum(album)
      })
    .value()

  if _.size(tracks) == 0
    throw 'no tracks'
  else
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
        try
          playlist = parsePlaylistDom window.$
        catch error
          console.trace error
          return callback(error)
        finally
          window.close()
        return callback(null, playlist)
  )

