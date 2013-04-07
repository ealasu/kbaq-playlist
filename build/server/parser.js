(function() {
  var getPlaylist, getPlaylistUrl, jsdom, moment, nodetime, parseAlbum, parsePlaylistDom, _,
    __slice = [].slice;

  _ = require('underscore');

  jsdom = require('jsdom');

  nodetime = require('time');

  moment = require('moment');

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
        text: text
      };
    }
  };

  parsePlaylistDom = function(selector) {
    var firstLineMatcher, inline_tags, lines, t, text, tracks, _i, _len;
    console.log(selector('html').html());
    text = selector('#main-content #content div.node-content div.field div.field-items').html();
    if (!text) {
      text = selector('#main-content #content div.node-content section div.field-items').last().html();
    }
    text = text.replace(/\s+/ig, ' ');
    text = text.replace(/(<br\s*\/?>)|(<\/div\s*>\s*<div[^>]*>)|(<div[^>]*>)|(<\/div\s*>)|(<p[^>]*>)|(<\/p\s*>)/ig, '\n');
    inline_tags = ['i', 'b', 'strong', 'em', 'span', 'a'];
    for (_i = 0, _len = inline_tags.length; _i < _len; _i++) {
      t = inline_tags[_i];
      text = text.replace(new RegExp("(<" + t + "[^>]*>)|(</" + t + "[^>]*>)", 'ig'), '');
    }
    lines = text.split('\n');
    firstLineMatcher = /^\s*(\d+:\d+(:\d+)?:?\s*[AP]M)\s*(.*$)/ig;
    tracks = _.chain(lines).map(function(line) {
      return selector('<span/>').html(line).text();
    }).reject(function(line) {
      return line.match(/\s*\d+\s*\|\s*\d+\s*/g);
    }).map(function(line) {
      return line.replace(/[\s-]*$/, '').replace(/^\s*/, '');
    }).partitionBy(function(line) {
      return line.match(/^[\s_]*$/);
    }).reject(function(group) {
      return _.any(group, function(line) {
        return line.match(/^[\s_]*$/);
      });
    }).filter(function(group) {
      return group[0].match(firstLineMatcher);
    }).map(function(group) {
      var album, artists, name, time, _j;
      console.log(group);
      time = group[0], name = group[1], artists = 4 <= group.length ? __slice.call(group, 2, _j = group.length - 1) : (_j = 2, []), album = group[_j++];
      return {
        'time': time,
        'name': name.trim(),
        'artists': artists,
        'album': parseAlbum(album)
      };
    }).value();
    if (_.size(tracks) === 0) {
      throw 'no tracks';
    } else {
      return {
        tracks: tracks
      };
    }
  };

  getPlaylistUrl = function(playlistDate) {
    return 'http://www.kbaq.org/content/' + (playlistDate === 'today' ? 'todays-playlist' : 'kbaq-playlist-' + playlistDate);
  };

  exports.getPlaylist = getPlaylist = function(playlistDate, callback) {
    var url;
    url = getPlaylistUrl(playlistDate);
    console.log(url);
    return jsdom.env(url, ['http://code.jquery.com/jquery-1.9.1.min.js'], function(errors, window) {
      var playlist;
      if (errors) {
        console.log('jsdom.env failed: ' + errors);
        return callback(errors);
      } else {
        try {
          playlist = parsePlaylistDom(window.$);
        } catch (error) {
          console.trace(error);
          return callback(error);
        } finally {
          window.close();
        }
        return callback(null, playlist);
      }
    });
  };

}).call(this);
