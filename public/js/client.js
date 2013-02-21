(function() {
  var highlightNowPlaying, loadPlaylist;

  loadPlaylist = function(date) {
    date = date.startOf('day');
    return $.getJSON('/playlist/' + date.format('MMDDYYYY'), function(playlist) {
      var nextDate, prevDate;
      playlist.date = date;
      _.each(playlist.tracks, function(track) {
        var rt, t;
        t = moment(track.time, 'h:mmA');
        rt = moment(date).hours(t.hours()).minutes(t.minutes());
        track._t = rt;
        track.id = rt.unix();
        return track.time = rt.format('h:mm a');
      });
      $('#tracks').html(Handlebars.templates['templates/trackList.hbs']({
        tracks: playlist.tracks
      }));
      prevDate = moment(date).subtract('days', 1);
      $('#navbar a.prev').data('date', prevDate);
      $('#navbar a.prev').text('« ' + prevDate.format('M/DD'));
      if (moment(date).diff(moment().startOf('day'), 'seconds') < 0) {
        nextDate = moment(date).add('days', 1);
        $('#navbar a.next').data('date', nextDate);
        $('#navbar a.next').text(nextDate.format('M/DD') + ' »');
        $('#navbar a.next').show();
      } else {
        $('#navbar a.next').hide();
      }
      if (moment().startOf('day').diff(playlist.date, 'seconds') === 0) {
        return highlightNowPlaying(playlist);
      }
    });
  };

  highlightNowPlaying = function(playlist) {
    var elem, now, playingTrack;
    now = moment();
    playingTrack = _.chain(playlist.tracks).filter(function(v) {
      return v._t <= now;
    }).max(function(v) {
      return v._t;
    }).value();
    elem = $('#' + playingTrack.id);
    $('.track').removeClass('now_playing');
    elem.addClass('now_playing');
    return $('html body').animate({
      scrollTop: elem.offset().top - ($(window).height() - elem.outerHeight()) / 2
    }, 100);
  };

  $(function() {
    var spinner, spinnerOpts;
    $(document).ajaxStart(function() {
      return $('#spinner').show();
    });
    $(document).ajaxStop(function() {
      return $('#spinner').hide();
    });
    spinnerOpts = {
      lines: 13,
      length: 7,
      width: 4,
      radius: 10,
      corners: 1,
      rotate: 0,
      color: '#000',
      speed: 1,
      trail: 60,
      shadow: false,
      hwaccel: false,
      className: 'spinner',
      zIndex: 2e9,
      top: 'auto',
      left: 'auto'
    };
    spinner = new Spinner(spinnerOpts).spin();
    $('#spinner').append(spinner.el);
    $('#navbar a.nav').click(function() {
      return loadPlaylist($(this).data('date'));
    });
    return loadPlaylist(moment());
  });

}).call(this);
