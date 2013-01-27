(function() {
  var currentPlaylist, highlightNowPlaying, loadPlaylist, today;

  _.mixin({
    findClosest: function(obj, val, getter) {
      var distance;
      distance = function(a, b) {
        return Math.abs(a - b);
      };
      return _.reduce(obj, function(a, b) {
        if (distance(val, getter(a)) < distance(val, getter(b))) {
          return a;
        } else {
          return b;
        }
      });
    }
  });

  currentPlaylist = null;

  loadPlaylist = function(date) {
    date = date.startOf('day');
    return $.getJSON('/playlist/' + date.format('MMDDYYYY'), function(playlist) {
      currentPlaylist = playlist;
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
      return highlightNowPlaying();
    });
  };

  highlightNowPlaying = function() {
    var elem, now, playingTrack;
    now = moment();
    playingTrack = _.findClosest(currentPlaylist.tracks, now, function(v) {
      return v._t;
    });
    elem = $('#' + playingTrack.id);
    $('.track').removeClass('now_playing');
    elem.addClass('now_playing');
    return $('html body').animate({
      scrollTop: elem.offset().top - ($(window).height() - elem.outerHeight()) / 2
    }, 100);
  };

  today = moment();

  loadPlaylist(today);

}).call(this);
