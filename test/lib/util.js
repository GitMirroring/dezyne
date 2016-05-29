// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
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
    .fail(function(err) { return {command:__dirname + '/../bin/' + path.basename(command), args:[path.dirname(command)].concat(aspects)}; });
}

if (!Array.prototype.append_map) {
  Array.prototype.append_map = function(lambda) {
    return [].concat.apply([], this.map(lambda));
  }
}

if (!Array.prototype.each) {
  Array.prototype.each = Array.prototype.forEach;
};

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
  identity: function (e) { return e; }
  ,
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
  writable: function(dir) {
    var stat = fs.lstatSync(dir);
    if (!stat) { return false; }
    var result =
        ( (process.getuid() == stat.uid) && (stat.mode & 00200) ) || // User is owner and owner can write.
        ( (process.getgid() == stat.gid) && (stat.mode & 00020) ) || // User is in group and group can write.
        ( stat.mode & 00002 ); // Anyone can write.
      return result;
  }
  ,
  spawn_sync_shell: function (cmd, timeout_ms) {
    var windows_p = /^win32/.test (process.platform);
    var shell = windows_p ? 'cmd.exe' : 'bash';
    var c = windows_p ? '/c' : '-c';
    console.log (cmd);

    var future = q.defer ();
    var p = child.spawn (shell, [c, cmd], {stdio:'inherit'});
    p.on('close', function (code, signal) {
      try {
        var exitcode = signal || code;
        future.resolve(exitcode);
      }
      catch (err) {
        future.resolve('ERROR');
      }
    })
    return timeout_ms ? future.promise
      .timeout(timeout_ms)
      .fail(function(msg){
        console.error(cmd + ' ' + msg);
        p.kill();
        return 'ERROR';
      })
    : future.promise;
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
      .then(function(call) {
        var stdout = '';
        var stderr = '';
        var output = '';
        var status = '';

        var script = child.spawn (call.command, call.args);

        script.stdout.on('data', function (data) {
          if(verbose) process.stdout.write(data);
          stdout += data;
          output += data;

          status = Object.keys(ST).reduce(function(status, key) {
            return util.contains(data, ST[key]) ? V(status, ST[key]) : status;
          }, status);

        });
        script.stderr.on('data', function (data) {
          if(verbose) process.stderr.write(data);
          stderr += data;
          output += data;
        });
        script.on('error', function (err) {
          console.error(err.stack);

          var result = {};
          result.status = ST.error;
          result.exitcode = 1;
          future.resolve(result);
        })

        script.on('exit', function (code, signal) {
          var result = {};
          result.status = status || ST.error;
          result.exitcode = signal || code;
          result.stdout = stdout;
          result.stderr = stderr;
          result.output = output;
          future.resolve(result);
        })
        return future.promise;
      })
      .fail(function(err) {
        console.error('[ERROR] ' + err.stack);
      })
      .then(function(result) {
        var singleTestEndTime = new Date();
        if(verbose)
          console.log('Elapsed time: ' + util.elapsedTime(singleTestStartTime, singleTestEndTime, true));
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
