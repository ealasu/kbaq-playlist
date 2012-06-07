var express = require('express');
var request = require('request');


if (process.env.REDISTOGO_URL) {
  var rtg   = require("url").parse(process.env.REDISTOGO_URL);
  var redis = require("redis").createClient(rtg.port, rtg.hostname);
  redis.auth(rtg.auth.split(":")[1]);
} else {
  var redis = require("redis").createClient();
}

var app = express.createServer(express.logger());

var default_url = 'http://kbaq.org/music/playlists/text?06022012_playlist.txt';


var getCached = function(url, callback) {
  redis.get(url, function(err, reply) {
    if (reply) {
      callback(reply);
    } else {
      request(url, function(req_error, response, body) {
        redis.set(url, body);
        callback(body);
      });
    }
  });
};


app.get('/', function(req, resp) {
  getCached(default_url, function(body) {
    resp.send(body);
  });
});

var port = process.env.PORT || 5000;
app.listen(port, function() {
  console.log("Listening on " + port);
});

