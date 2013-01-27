
loadPlaylist = (date) ->
  $.getJSON '/playlist/' + date, (playlist) ->
    $('#tracks').html Handlebars.templates['templates/trackList.hbs'](
      tracks: playlist.tracks)
    #_.each playlist.tracks, (track) ->
    #  track.id = track.time
    #  $('#tracks').append Handlebars.templates['templates/track.hbs'](track)

today = moment().format('MMDDYYYY')

loadPlaylist today
