
_.mixin {
  findClosest: (obj, val, getter) ->
    distance = (a, b) -> Math.abs(a - b)
    _.reduce obj, (a, b) ->
      if distance(val, getter(a)) < distance(val, getter(b)) then a else b
}


currentPlaylist = null

loadPlaylist = (date) ->
  date = date.startOf('day')
  $.getJSON '/playlist/' + date.format('MMDDYYYY'), (playlist) ->
    currentPlaylist = playlist
    _.each playlist.tracks, (track) ->
      t = moment(track.time, 'h:mmA')
      rt = moment(date).hours(t.hours()).minutes(t.minutes())
      track._t = rt
      track.id = rt.unix()
      track.time = rt.format('h:mm a')
    $('#tracks').html Handlebars.templates['templates/trackList.hbs'](
      tracks: playlist.tracks)
    highlightNowPlaying()
    
highlightNowPlaying = () ->
  now = moment()
  playingTrack = _.findClosest currentPlaylist.tracks, now, (v) -> v._t
  elem = $('#' + playingTrack.id)
  $('.track').removeClass('now_playing')
  elem.addClass('now_playing')
  $('html body').animate({scrollTop: elem.offset().top - ($(window).height() - elem.outerHeight()) / 2}, 100)


today = moment()

loadPlaylist today
