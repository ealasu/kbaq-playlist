(function() {
  var app, express, getCachedPlaylist, getPlaylist, getPlaylistUrl, getTodaysDateString, handlePlaylistRequest, http, jsdom, moment, nodetime, parseAlbum, parsePlaylist, path, redis, request, rtg, _;

  express = require('express');

  request = require('request');

  jsdom = require('jsdom');

  _ = require('underscore');

  path = require('path');

  http = require('http');

  nodetime = require('time');

  moment = require('moment');

  process.env.TZ = 'UTC';

  if (process.env.REDISTOGO_URL) {
    console.log('Redis url: %s', process.env.REDISTOGO_URL);
    rtg = require("url").parse(process.env.REDISTOGO_URL);
    redis = require("redis").createClient(rtg.port, rtg.hostname);
    redis.auth(rtg.auth.split(":")[1]);
  } else {
    redis = require("redis").createClient();
  }

  _.mixin({
    partitionBy: function(obj, val) {
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
    }
  });

  parseAlbum = function(text) {
    var match;
    match = /(.*?)\s*(\d+)/g.exec(text);
    if (match !== null) {
      return {
        label: match[1],
        catalog: match[2]
      };
    } else {
      return {
        name: text
      };
    }
  };

  parsePlaylist = function(selector, callback) {
    var firstLineMatcher, lines, playlistDate, text, tracks;
    text = selector('p').text();
    lines = text.split('\n');
    playlistDate = /Playlist for (.+?)\s*$/g.exec(selector('h4').first().text())[1];
    console.log('playlist date: ' + playlistDate);
    firstLineMatcher = /^\s*(\d+:\d+(:\d+)?:?\s*[AP]M)\s*(.*$)/i;
    tracks = _.chain(lines).reject(function(line) {
      return line.match(/\s*\d+\s*\|\s*\d+\s*/g);
    }).partitionBy(function(line) {
      return line.match(/^[\s_]*$/);
    }).reject(function(group) {
      return _.any(group, function(line) {
        return line.match(/^[\s_]*$/);
      });
    }).filter(function(group) {
      return group[0].match(firstLineMatcher);
    }).map(function(group) {
      return _.map(group, function(line) {
        return line.trim().replace(/\s*-$/, '');
      });
    }).map(function(group) {
      var firstLine, match, name, time;
      firstLine = group[0];
      group = _.rest(group);
      match = firstLine.match(firstLineMatcher);
      if (match) {
        time = match[1];
        name = match[3].trim();
        if (!name) {
          name = group[0];
          group = _.rest(group);
        }
        return {
          'time': time,
          'name': name,
          'artists': _.initial(group),
          'album': parseAlbum(_.last(group))
        };
      } else {
        return console.log('ERROR: failed match on time line, ' + firstLine + '\n' + group);
      }
    }).value();
    if (_.size(tracks) === 0) {
      return callback('no tracks');
    } else {
      return callback(null, {
        tracks: tracks
      });
    }
  };

  getPlaylistUrl = function(playlistDate) {
    return 'http://kbaq.org/music/playlists/text?' + playlistDate + '_playlist.txt';
  };

  getPlaylist = function(playlistDate, callback) {
    return jsdom.env(getPlaylistUrl(playlistDate), ['http://code.jquery.com/jquery-1.5.min.js'], function(errors, window) {
      if (errors) {
        console.log('jsdom.env failed: ' + errors);
        return callback(errors);
      } else {
        return parsePlaylist(window.$, function(errors, playlist) {
          callback(errors, playlist);
          return window.close();
        });
      }
    });
  };

  getCachedPlaylist = function(playlistDate, callback) {
    var cacheKey;
    cacheKey = playlistDate;
    return redis.get(cacheKey, function(err, reply) {
      if (err) {
        return callback(err);
      } else if (reply) {
        console.log('cache hit for %s', cacheKey);
        return callback(null, JSON.parse(reply));
      } else {
        console.log('cache miss for %s', cacheKey);
        return getPlaylist(playlistDate, function(errors, playlist) {
          if (errors) {
            console.log('getPlaylist failed: ' + errors);
            return callback(errors);
          } else {
            redis.set(cacheKey, JSON.stringify(playlist));
            return callback(null, playlist);
          }
        });
      }
    });
  };

  getTodaysDateString = function() {
    var now;
    now = new nodetime.Date();
    now.setTimezone('America/Phoenix');
    return moment(now).format('MMDDYYYY');
  };

  app = express();

  app.configure(function() {
    app.set('port', process.env.PORT || 5000);
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.logger('dev'));
    return app.use(express["static"](path.join(__dirname, '../client')));
  });

  handlePlaylistRequest = function(playlistDate, req, res) {
    return getCachedPlaylist(playlistDate, function(errors, playlist) {
      if (errors) {
        console.log('getCachedPlaylist failed: ' + errors);
        return res.send(500);
      } else {
        return res.send(playlist);
      }
    });
  };

  app.get('/playlist/today', function(req, res) {
    return handlePlaylistRequest(getTodaysDateString(), req, res);
  });

  app.get('/playlist/:date', function(req, res) {
    return handlePlaylistRequest(req.params.date, req, res);
  });

  http.createServer(app).listen(app.get('port'), function() {
    return console.log("Listening on " + app.get('port'));
  });

}).call(this);
