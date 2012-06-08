var express = require('express');
var request = require('request');
var jsdom = require('jsdom');
var _ = require('underscore');
require('datejs');


if (process.env.REDISTOGO_URL) {
  var rtg   = require("url").parse(process.env.REDISTOGO_URL);
  var redis = require("redis").createClient(rtg.port, rtg.hostname);
  redis.auth(rtg.auth.split(":")[1]);
} else {
  var redis = require("redis").createClient();
}

var default_date = Date.today();

var partitionBy = function(obj, val) {
  var last = [];
  var result = [last];
  var lastVal = null;
  _.each(obj, function(value, index) {
    var currentVal = val(value);
    if (currentVal !== lastVal && index > 0) {
      last = [];
      result.push(last);
    }
    lastVal = currentVal;
    last.push(value);
  });
  return result;
};

var parsePlaylist = function(selector, callback) {
  var text = selector('p').text();
  var lines = text.split('\n');
  var playlistDate = new Date(/Playlist for (.+?)\s*$/g.exec(selector('h4').first().text())[1]);
  
  var result = lines;
  result = _.filter(result, function(val){ return !val.match(/\s*\d+\s*\|\s*\d+\s*/g); });
  result = partitionBy(result, function(val){ return val.match(/^[\s_]*$/); });
  result = _.filter(result, function(val){ return !_.any(val, function(v2){return v2.match(/^[\s_]*$/);}); });
  result = _.filter(result, function(val){ return val[0].match(/^\s*\d+:\d+.*$/); });
  result = _.map(result, function(val){ 
    return _.map(val, function(val2){ 
      return val2.trim(); }); });

  result = _.map(result, function(val) {
    var first = val[0].match(/^\s*(\d+:\d+\s*[AP]M)\s*(.+$)/i);
    if (first) {
      return {
      'time': Date.parse(playlistDate.toString('M/d/yyyy') + ' ' + first[1]),
      'name': first[2],
      'artists': _.initial(_.rest(val)),
      'album': _.last(val)
      };
    }
  });

  return result;
}

var getPlaylistUrl = function(playlistDate) {
  return 'http://kbaq.org/music/playlists/text?' + playlistDate.toString('MMddyyyy') + '_playlist.txt';
};

var getPlaylist = function(playlistDate, callback) {
  console.log(playlistDate);
  console.log(playlistDate.addHours(-7));
  console.log(new Date().toString('MMddyyyy'));
  jsdom.env(getPlaylistUrl(playlistDate.addHours(-7)), [
    'http://code.jquery.com/jquery-1.5.min.js'
  ],
  function(errors, window) {
    callback(parsePlaylist(window.$));
    window.close();
  });
};

var getCached = function(playlistDate, callback) {
  redis.get(playlistDate+'x', function(err, reply) {
    if (reply) {
      callback(JSON.parse(reply));
    } else {
      getPlaylist(playlistDate, function(playlist) {
        redis.set(playlistDate, JSON.stringify(playlist));
        callback(playlist);
      });
    }
  });
};


var app = express.createServer(express.logger());

app.configure(function() {
  app.use(express.static(__dirname + '/public'));
  app.set('view engine', 'jade');
});

app.get('/', function(req, res) {
  getCached(Date.today(), function(playlist) {
    res.render('index', {
      'title': "Today's playlist", 
      'playlist': playlist
    });
  });
});

app.get('/playlist/:date', function(req, res) {
  getCached(Date.parse(req.params.date), function(body) {
    res.send(body);
  });
});

var port = process.env.PORT || 5000;
app.listen(port, function() {
  console.log("Listening on " + port);
});

