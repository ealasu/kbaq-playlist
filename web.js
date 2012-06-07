var express = require('express');
var request = require('request');
var redis = require('redis');

var client = redis.createClient();
var app = express.createServer(express.logger());

var default_url = 'http://kbaq.org/music/playlists/text?06022012_playlist.txt';


var getCached = function(url, callback) {
  client.get(url, function(err, reply) {
    if (!reply) {
      request(url, function(req_error, response, body) {
        client.set(url, body);
        callback(reply);
      });
    } else {
      callback(reply);
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

