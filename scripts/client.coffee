
today = '01262013'

console.log Handlebars.template

# div.track(id=track.time)
#   p.time= track['time']
#   p.name= track['name']
#   div.artists
#     each artist in track.artists
#       p.artist= artist
#   p.album= track['album']


loadPlaylist = (date) ->
  $.getJSON '/playlist/' + date, (playlist) ->
    _.each playlist.tracks, (track) ->
      elem = $('<track/>')

      track.id = track.time

loadPlaylist today
