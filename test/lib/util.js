// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

if (!Array.prototype.partition) {
  Array.prototype.partition = function (predicate, context) {
    var satisfy = [];
    var rest = [];

    this.each (function (i) {
      if (predicate.call (context, i)) {
        satisfy.push (i);
      } else {
        rest.push (i);
      }
    });
    return [satisfy, rest];
  };
};

var ST = { error: '[ERROR]', failed: '[FAILED]', ok: '[OK]', skipped: '[SKIPPED]', known: '[KNOWN]', solved: '[SOLVED]'};

function V(st1, st2) {
  if (st1 == ST.error || st2 == ST.error) return ST.error;
  if (st1 == ST.failed || st2 == ST.failed) return ST.failed;
  if (st1 == ST.known || st2 == ST.known) return ST.known;
  if (st1 == ST.solved || st2 == ST.solved) return ST.solved;
  if (st1 == ST.ok || st2 == ST.ok) return ST.ok;
  return ST.skipped;
}

function delay(ms) {
  var deferred = q.defer();
  setTimeout(deferred.resolve, ms);
  return deferred.promise;
}

if (!Array.prototype.find) {
  Array.prototype.find = function(predicate) {
    if (this === null) {
      throw new TypeError('Array.prototype.find called on null or undefined');
    }
    if (typeof predicate !== 'function') {
      throw new TypeError('predicate must be a function');
    }
    var list = Object(this);
    var length = list.length >>> 0;
    var thisArg = arguments[1];
    var value;

    for (var i = 0; i < length; i++) {
      value = list[i];
      if (predicate.call(thisArg, value, i, list)) {
        return value;
      }
    }
    return undefined;
  };
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
  relative: function (file_name) {
    return fs.realpathSync (file_name)
      .replace (new RegExp ('^' + fs.realpathSync (process.cwd ()) + '/'), '');
  }
  ,
  result: function(r) {
    return q(r);
  }
  ,
  deep_copy: function(obj) {
    return JSON.parse(JSON.stringify(obj));
  }
  ,
  parallel_n: function (list /*list of q returning lambdas*/, max) {
    function next(session, promises) {
      return q().then(function(){
        if(promises.length < list.length) {
          var pool = promises.filter(function(e){ return !e.isFulfilled();});
          var promise = list[promises.length](session);
          promises.push(promise);
          pool.push(promise);
          return q.any(pool)
            .then(function(result){return next(result.session, promises);});
        }
        return q.all(promises);
      });
    }

    var promises = list.slice(0,max).map(function(e, i) {return e(100 + i);});

    return q.any(promises)
      .then(function(result){return next(result.session, promises);});
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
  spawn_sync_shell: function (cmd, options) {
    var windows_p = /^win32/.test (process.platform);
    var shell = windows_p ? 'cmd.exe' : 'bash';
    var c = windows_p ? '/c' : '-c';

    var future = q.defer ();

    var env = JSON.parse(JSON.stringify(process.env));
    options = options || { env:env, timeout_ms:0};
    env.NODE_PATH = process.cwd() + '/node_modules:' + env.NODE_PATH;

    var ulimit = 'ulimit -s 65536 -v 2097152;';

    var p = child.spawn (shell, [c, ulimit + cmd], {env: env});

    var output = printable_cmd + '\n';

    var printable_cmd = cmd.replace (/\r/g, '\\r');
    console.log (printable_cmd);

    p.stdout.on('data', function(data){process.stdout.write(data); output += data;});
    p.stderr.on('data', function(data){process.stderr.write(data); output += data;});

    p.on('exit', function (code, signal) {
      future.resolve({status: signal ? -1 : code ? 1 : 0, output: output});
    })

    return options.timeout_ms
      ? future.promise
      .timeout(timeout_ms)
      .fail(function(msg){
        console.error(cmd + ' ' + msg);
        console.error('killing PID: ' + p.pid);
        process.kill(-p.pid);
        return {status: -1, output: msg};
      })
    : future.promise;
  }
  ,
  contains: function(buffer, sub) {
    return (buffer.toString().indexOf(sub) > -1);
  }
  ,
  // run script arguments: bin/run testdir (aspect | language)*
  //                       testdir/run (aspect | language)*
  run: function(session, testdir, aspects_languages, verbose, quiet) {
    var future = q.defer();
    var singleTestStartTime = new Date();

    var lstat = q.denodeify(fs.lstat);
    return lstat(testdir + '/run')
      .then(function(stats) { return {run: testdir + '/run', args: [session].concat(aspects_languages)}; })
      .fail(function(err) { return {run: __dirname + '/../bin/run', args: [session, util.relative (testdir)].concat(aspects_languages)}; })
      .then(function(call) {
        var stdout = '';
        var stderr = '';
        var output = '';
        var status = '';
        var remaining = '';

        var script = child.spawn (call.run, call.args, {stdio: 'pipe'});

        script.stdout.on('data', function (data) {
          remaining += data;
          var index = remaining.indexOf('\n');
          var last = 0;
          while (index > -1) {
            var line = remaining.substring(last, index);
            last = index + 1;
            if((!quiet || verbose) && remaining.startsWith('update:')) {
              console.log(line.replace('update:',''));
            }
            else if(verbose) console.log(line);
            status = Object.keys(ST).reduce(function(status, key) {
              return util.contains(line, ST[key]) ? V(status, ST[key]) : status;
            }, status);
            index = remaining.indexOf('\n', last);
          }
          remaining = remaining.substring(last);
        });
        script.stderr.on('data', function (data) {
          if(verbose) process.stderr.write(data);
        });
        script.on('error', function (err) {
          console.error(err.stack);

          var result = {};
          result.status = ST.error;
          result.exitcode = 1;
          future.resolve(result);
        })

        function resolve (code) {
          var result = {};
          result.status = status;
          result.exitcode = code;
          result.stdout = stdout;
          result.stderr = stderr;
          result.output = output;
          return future.resolve(result);
        }

        script.on('close', function (code) {
          return resolve (code);
        });

        script.on('exit', function (code, signal) {
          status = status || ST.error;
          return resolve (signal || code);
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
  version_split: function (v) {
    var split = v.split ('.');
    if (split.length == 1)
      return [v]
    return split.map (function (s){return parseInt (s);});
  }
  ,
  version_compare: function (a,b) {
    var va = util.version_split (a);
    var vb = util.version_split (b);
    if (isNaN (va[0])) {
      if (isNaN (vb[0])) return a.localeCompare (b);
      return 1;
    }
    if (isNaN (vb[0])) return -1;

    for (i = 0; i < Math.min (va.length, vb.length); i++) {
      if (va[i] < vb[i]) return -1;
      if (va[i] > vb[i]) return 1;
    }

    return 0;
  }
};


module.exports = util;
