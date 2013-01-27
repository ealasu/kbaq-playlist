(function() {
  var app, default_date, express, getCachedPlaylist, getPlaylist, getPlaylistUrl, http, jsdom, moment, parsePlaylist, partitionBy, path, redis, request, rtg, time, _;

  express = require('express');

  request = require('request');

  jsdom = require('jsdom');

  _ = require('underscore');

  path = require('path');

  http = require('http');

  require('datejs');

  time = require('time')(Date);

  moment = require('moment');

  if (process.env.REDISTOGO_URL) {
    console.log('Redis url: %s', process.env.REDISTOGO_URL);
    rtg = require("url").parse(process.env.REDISTOGO_URL);
    redis = require("redis").createClient(rtg.port, rtg.hostname);
    redis.auth(rtg.auth.split(":")[1]);
  } else {
    redis = require("redis").createClient();
  }

  default_date = Date.today();

  partitionBy = function(obj, val) {
    var last, lastVal, result;
    last = [];
    result = [last];
    lastVal = null;
    _.each(obj, function(value, index) {
      var currentVal;
      currentVal = val(value);
      if (currentVal !== lastVal && index > 0) {
        last = [];
        result.push(last);
      }
      lastVal = currentVal;
      return last.push(value);
    });
    return result;
  };

  parsePlaylist = function(selector) {
    var lines, playlistDate, result, text;
    text = selector('p').text();
    lines = text.split('\n');
    playlistDate = new Date(/Playlist for (.+?)\s*$/g.exec(selector('h4').first().text())[1]);
    console.log(playlistDate);
    result = lines;
    result = _.filter(result, function(line) {
      return !line.match(/\s*\d+\s*\|\s*\d+\s*/g);
    });
    result = partitionBy(result, function(line) {
      return line.match(/^[\s_]*$/);
    });
    result = _.filter(result, function(group) {
      return !_.any(group, function(line) {
        return line.match(/^[\s_]*$/);
      });
    });
    result = _.filter(result, function(group) {
      return group[0].match(/^\s*\d+:\d+.*$/);
    });
    result = _.map(result, function(group) {
      return _.map(group, function(line) {
        return line.trim();
      });
    });
    result = _.map(result, function(group) {
      var match, playTime;
      match = group[0].match(/^\s*(\d+:\d+\s*[AP]M)\s*(.+$)/i);
      if (match) {
        playTime = match[1];
        return {
          'time': playTime,
          'name': match[2],
          'artists': _.initial(_.rest(group)),
          'album': _.last(group)
        };
      }
    });
    return {
      tracks: result
    };
  };

  getPlaylistUrl = function(playlistDate) {
    return 'http://kbaq.org/music/playlists/text?' + playlistDate + '_playlist.txt';
  };

  getPlaylist = function(playlistDate, callback) {
    return jsdom.env(getPlaylistUrl(playlistDate), ['http://code.jquery.com/jquery-1.5.min.js'], function(errors, window) {
      callback(parsePlaylist(window.$));
      return window.close();
    });
  };

  getCachedPlaylist = function(playlistDate, callback) {
    var cacheKey;
    cacheKey = playlistDate;
    return redis.get(cacheKey, function(err, reply) {
      if (reply) {
        console.log('cache hit for %s', cacheKey);
        return callback(JSON.parse(reply));
      } else {
        console.log('cache miss for %s', cacheKey);
        return getPlaylist(playlistDate, function(playlist) {
          redis.set(cacheKey, JSON.stringify(playlist));
          return callback(playlist);
        });
      }
    });
  };

  app = express();

  app.configure(function() {
    app.set('port', process.env.PORT || 5000);
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.logger('dev'));
    return app.use(express["static"](path.join(__dirname, 'public')));
  });

  app.get('/playlist/:date', function(req, res) {
    return getCachedPlaylist(req.params.date, function(playlist) {
      return res.send(playlist);
    });
  });

  http.createServer(app).listen(app.get('port'), function() {
    return console.log("Listening on " + app.get('port'));
  });

}).call(this);
