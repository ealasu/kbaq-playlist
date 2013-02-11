
_.mixin {
  distance: (a, b) -> 
    Math.abs(a - b)
  findClosest: (obj, val, getter) ->
    _.reduce obj, (a, b) ->
      if _.distance(val, getter(a)) < _.distance(val, getter(b)) then a else b
}


loadPlaylist = (date) ->
  date = date.startOf('day')
  #showSpinner()
  $.getJSON '/playlist/' + date.format('MMDDYYYY'), (playlist) ->
    playlist.date = date
    _.each playlist.tracks, (track) ->
      t = moment(track.time, 'h:mmA')
      rt = moment(date).hours(t.hours()).minutes(t.minutes())
      track._t = rt
      track.id = rt.unix()
      track.time = rt.format('h:mm a')
    $('#tracks').html Handlebars.templates['templates/trackList.hbs'](
      tracks: playlist.tracks)
    prevDate = moment(date).subtract('days', 1)
    $('#navbar a.prev').data 'date', prevDate
    $('#navbar a.prev').text '« ' + prevDate.format('M/DD')
    if moment(date).diff(moment().startOf('day'), 'seconds') < 0
      nextDate = moment(date).add('days', 1)
      $('#navbar a.next').data 'date', nextDate
      $('#navbar a.next').text nextDate.format('M/DD') + ' »'
      $('#navbar a.next').show()
    else
      $('#navbar a.next').hide()
    if moment().startOf('day').diff(playlist.date, 'seconds') == 0
      highlightNowPlaying(playlist)
    
highlightNowPlaying = (playlist) ->
  now = moment()
  playingTrack = _.findClosest playlist.tracks, now, (v) -> v._t
  elem = $('#' + playingTrack.id)
  $('.track').removeClass('now_playing')
  elem.addClass('now_playing')
  $('html body').animate({scrollTop: elem.offset().top - ($(window).height() - elem.outerHeight()) / 2}, 100)


$(document).ajaxStart ->
  $('#spinner').show()

$(document).ajaxStop ->
  $('#spinner').hide()
  

$ ->

  $('#navbar a.nav').click ->
    loadPlaylist($(this).data('date'))

  spinnerOpts =
    lines: 13, # The number of lines to draw
    length: 7, # The length of each line
    width: 4, # The line thickness
    radius: 10, # The radius of the inner circle
    corners: 1, # Corner roundness (0..1)
    rotate: 0, # The rotation offset
    color: '#000', # #rgb or #rrggbb
    speed: 1, # Rounds per second
    trail: 60, # Afterglow percentage
    shadow: false, # Whether to render a shadow
    hwaccel: false, # Whether to use hardware acceleration
    className: 'spinner', # The CSS class to assign to the spinner
    zIndex: 2e9, # The z-index (defaults to 2000000000)
    top: 'auto', # Top position relative to parent in px
    left: 'auto' # Left position relative to parent in px
  spinner = new Spinner(spinnerOpts).spin()
  $('#spinner').append(spinner.el)

  loadPlaylist moment()
