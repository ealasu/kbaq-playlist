(function() {
  var loadPlaylist, today;

  loadPlaylist = function(date) {
    return $.getJSON('/playlist/' + date, function(playlist) {
      return $('#tracks').html(Handlebars.templates['templates/trackList.hbs']({
        tracks: playlist.tracks
      }));
    });
  };

  today = moment().format('MMDDYYYY');

  loadPlaylist(today);

}).call(this);
