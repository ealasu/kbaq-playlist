express = require('express')
request = require('request')
jsdom = require('jsdom')
_ = require('underscore')
time = require('time')(Date)
require('datejs')


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
  console.log(playlistDate)
  return 'http://kbaq.org/music/playlists/text?' + playlistDate.toString('MMddyyyy') + '_playlist.txt';

getPlaylist = (playlistDate, callback) ->
  playlistDate.setTimezone('MST')
  console.log(playlistDate);
  console.log(new Date().toString());
  jsdom.env(
    getPlaylistUrl(playlistDate), 
    ['http://code.jquery.com/jquery-1.5.min.js'],
    (errors, window) ->
      callback(parsePlaylist(window.$))
      window.close()
  )


getPlaylist new Date(), (playlist) ->
  console.log playlist

