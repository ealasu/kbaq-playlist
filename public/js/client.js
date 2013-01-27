(function() {
  var loadPlaylist, today;

  today = '01262013';

  loadPlaylist = function(date) {
    return $.getJSON('/playlist/' + date, function(playlist) {
      return $('#tracks').html(Handlebars.templates['templates/trackList.hbs']({
        tracks: playlist.tracks
      }));
    });
  };

  loadPlaylist(today);

}).call(this);
