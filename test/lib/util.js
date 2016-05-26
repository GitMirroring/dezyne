// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

var q = require('q');
var fs = require('fs');
var path = require('path');
var child = require('child_process');
var spawn = require('child_process').spawn;

var ST = { error: '[ERROR]', failed: '[FAILED]', ignored: '[IGNORED]', ok: '[OK]', skipped: '[SKIPPED]' };

function V(st1, st2) {
 if (st1 == ST.error || st2 == ST.error) return ST.error;
 if (st1 == ST.failed || st2 == ST.failed) return ST.failed;
 if (st1 == ST.ignored || st2 == ST.ignored) return ST.ignored;
 if (st1 == ST.ok || st2 == ST.ok) return ST.ok;
 return ST.skipped;
}

function delay(ms) {
    var deferred = q.defer();
    setTimeout(deferred.resolve, ms);
    return deferred.promise;
}

function getcall(command,aspects) {
  var lstat = q.denodeify(fs.lstat);
  return lstat(command)
  .then(function(stats) { return {command:command, args:aspects}; })
  .fail(function(err) { return {command:__dirname + '/' + path.basename(command), args:[path.dirname(command)].concat(aspects)}; });
}

if (!Array.prototype.append_map) {
  Array.prototype.append_map = function(lambda) {
    return [].concat.apply([], this.map(lambda));
  }
}

if (!Array.prototype.unique) {
  Array.prototype.unique = function (compare) {
    if (this == null) return [];
    if(compare) {
      return this.filter(function(elem, pos) {
        for(var i = 0; i < pos; ++i) {
          if(compare(elem, this[i])) return false;
        }
        return true;
      }.bind (this));
    } else {
      return this.filter(function(elem, pos) {
        return this.indexOf(elem) == pos;
      }.bind(this));
    }
  };
};

var util = {

  result: function(r) {
    return q(r);
  }
  ,
  parallel_n: function (list /*list of q returning lambdas*/, max) {
    function next(promises) {
      return q().then(function(){
        if(promises.length < list.length) {
          var pool = promises.filter(function(e){ return !e.isFulfilled();});
          var promise = list[promises.length]();
          promises.push(promise);
          pool.push(promise);
          return q.any(pool)
            .then(function(){return next(promises);});
        }
        return q.all(promises);
      });
    }

    var promises = list.slice(0,max).map(function(e) {return e();});

    return q.any(promises)
      .then(function(){return next(promises);});
  }
  ,
  spawn_sync_shell: function (cmd, options) {
    options = options || {stdio:'inherit'};
    var windows_p = /^win32/.test (process.platform);
    var shell = windows_p ? 'cmd.exe' : 'bash';
    var c = windows_p ? '/c' : '-c';
    console.log ([cmd].join (' '));
    return util.spawn_sync (shell, [c, cmd], options);
  }
  ,
  spawn_sync: function (cmd, args, options) {
    options = options || {stdio:'inherit'};
    var future = q.defer ();
    var process = child.spawn (cmd, args, options);
    process.on('close', function (code, signal) {
      try {
        var returncode = signal || code;
        future.resolve(returncode);
      }
      catch (err) {
        future.resolve('ERROR');
      }
    });
    return future.promise;
  }
  ,
  contains: function(buffer, sub) {
    return (buffer.toString().indexOf(sub) > -1);
  }
  ,
  run: function(command, aspects, verbose) {
    var future = q.defer();
    var singleTestStartTime = new Date();
    return getcall(command,aspects)
    .then (function(call) {
      try { script = spawn (call.command, call.args); }
      catch (err) { console.log('==== === ERROR: ' + err); throw (err); }

      var stdout = '';
      var stderr = '';
      var output = '';
      var status = '';
      script.stdout.on('data', function (data) {
        if(verbose) process.stdout.write(data);
        stdout += data;
        output += data;
        if (util.contains(data, ST.ok)) status = V(status, ST.ok);
        if (util.contains(data, ST.failed)) status = V(status, ST.failed);
        if (util.contains(data, ST.skipped)) status = V(status, ST.skipped);
        if (util.contains(data, ST.ignored)) status = V(status, ST.ignored);
        if (util.contains(data, ST.error)) status = V(status, ST.error);
      });
      script.stderr.on('data', function (data) {
        if(verbose) process.stderr.write(data);
        stderr += data;
        output += data;
      });
      script.on('close', function (code, signal) {
        var result = {};
        try {
          result.status = status || ST.error;
          result.returncode = signal || code;
          result.stdout = stdout;
          result.stderr = stderr;
          result.output = output;
          future.resolve(result);
        }
        catch (err) {
          result.status = ST.error;
          result.returncode = 1;
          result.stdout = err.toString();
          future.resolve(result);
        }
      });
      return future.promise;
    })
    .fail(function(err) {
      console.log('RUN ERROR: ' + run);
    })
    .then(function(result) {
      var singleTestEndTime = new Date();
      if(verbose) console.log('\nElapsed time: ' + util.elapsedTime(singleTestStartTime, singleTestEndTime, true));
      return result;
    });
  }
  ,
  elapsedTime: function(startTime, endTime, showMs) {
    var timeDiff = endTime - startTime;
    var milliSeconds = Math.round(timeDiff % 1000).toString();
    var pad = '000';
    milliSeconds = pad.substring(0, pad.length - milliSeconds.length) + milliSeconds;
    timeDiff = Math.floor(timeDiff / 1000);
    var seconds = Math.round(timeDiff % 60);
    timeDiff = Math.floor(timeDiff / 60);
    var minutes = Math.round(timeDiff % 60);
    timeDiff = Math.floor(timeDiff / 60);
    var hours = Math.round(timeDiff % 24);
    var days = Math.floor(timeDiff / 24);
    var timeString;
    if ((showMs && milliSeconds) || seconds || minutes || hours || days) {
      if (showMs) {
        timeString = seconds + '.' + milliSeconds + 's';
      }
      else {
        timeString = seconds + 's';
      }
      if (minutes || hours || days) {
        timeString = minutes + 'm' + ' ' + timeString;
        if (hours || days) {
          timeString = hours + 'h' + ' ' + timeString;
          if (days) {
            timeString = days + 'd' + ' ' + timeString;
          }
        }
      }
    }
    else {
      timeString = 'Wow!';
    }
    return timeString;
  }
  ,
};


module.exports = util;
