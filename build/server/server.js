(function() {
  var app, express, getCachedPlaylist, getYesterdaysDateString, handlePlaylistRequest, http, jsdom, moment, nodetime, parser, path, redis, request, rtg, _;

  process.env.TZ = 'UTC';

  express = require('express');

  request = require('request');

  jsdom = require('jsdom');

  _ = require('underscore');

  path = require('path');

  http = require('http');

  nodetime = require('time');

  moment = require('moment');

  parser = require('./parser');

  if (process.env.REDISTOGO_URL) {
    console.log('Redis url: %s', process.env.REDISTOGO_URL);
    rtg = require("url").parse(process.env.REDISTOGO_URL);
    redis = require("redis").createClient(rtg.port, rtg.hostname);
    redis.auth(rtg.auth.split(":")[1]);
  } else {
    redis = require("redis").createClient();
  }

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
        return parser.getPlaylist(playlistDate, function(errors, playlist) {
          if (errors) {
            console.log('getPlaylist failed: ' + errors);
            return callback(errors);
          } else {
            if (playlistDate !== 'today') {
              redis.set(cacheKey, JSON.stringify(playlist));
            }
            return callback(null, playlist);
          }
        });
      }
    });
  };

  getYesterdaysDateString = function() {
    var now;
    now = new nodetime.Date();
    now.setTimezone('America/Phoenix');
    return moment(now).subtract('days', 1).format('MM-DD-YYYY');
  };

  app = express();

  app.configure(function() {
    app.set('port', process.env.PORT || 5000);
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.logger('dev'));
    return app.use(express["static"](path.join(__dirname, '../client')));
  });

  handlePlaylistRequest = function(date, req, res) {
    return getCachedPlaylist(date, function(errors, playlist) {
      if (errors) {
        console.log('getCachedPlaylist failed: ' + errors);
        return res.send(500);
      } else {
        return res.send(playlist);
      }
    });
  };

  app.get('/playlist/yesterday', function(req, res) {
    return handlePlaylistRequest(getYesterdaysDateString(), req, res);
  });

  app.get('/playlist/:date', function(req, res) {
    return handlePlaylistRequest(req.params.date, req, res);
  });

  http.createServer(app).listen(app.get('port'), function() {
    return console.log("Listening on " + app.get('port'));
  });

}).call(this);
