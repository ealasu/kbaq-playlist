
today = '01262013'

# div.track(id=track.time)
#   p.time= track['time']
#   p.name= track['name']
#   div.artists
#     each artist in track.artists
#       p.artist= artist
#   p.album= track['album']


loadPlaylist = (date) ->
  $.getJSON '/playlist/' + date, (playlist) ->
    $('#tracks').html Handlebars.templates['templates/trackList.hbs'](
      tracks: playlist.tracks)
    #_.each playlist.tracks, (track) ->
    #  track.id = track.time
    #  $('#tracks').append Handlebars.templates['templates/track.hbs'](track)


loadPlaylist today
