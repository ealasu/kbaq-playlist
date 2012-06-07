var express = require('express');
var request = require('request');

var app = express.createServer(express.logger());

app.get('/', function(req, resp) {
  request('http://kbaq.org/music/playlists/text?06022012_playlist.txt', function(error, response, body) {


    resp.send(body);
  });
});

var port = process.env.PORT || 5000;
app.listen(port, function() {
  console.log("Listening on " + port);
});

