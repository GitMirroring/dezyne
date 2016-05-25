// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
var util = require(__dirname+'/util');
var lstat = q.denodeify(fs.lstat);

function skip_filter(work, dir) {
  try {
    fs.lstatSync(dir+'/SKIP');
    var skip_list = fs.readFileSync(dir+'/SKIP').toString().split('\n');
    return work.filter(function (e) {return skip_list.indexOf(e) == -1;});
  } catch (e) {}
  return work;
}

var dependencies = {
  code:     [],
  execute:  ['traces', 'build'],
  build:    ['code'],
  convert:  [],
  parse:    [],
  run:      ['traces'],
  table:    [],
  tables:   [],
  traces:   [],
  triangle: ['execute', 'run'],
  verify:   [],
  view:     [],
};

function depend(e) {
  return dependencies[e].concat(dependencies[e].append_map(depend));
}

var aspects = {
  all: function(work, dir) {
    work = skip_filter(work.length == 0 || work[0] == 'all' ? Object.keys(dependencies) : work, dir);

    var skip = Object.keys(dependencies).filter(function(e) { return work.indexOf(e) == -1; });
    skip.map(function(e) { console.log(e + ': [SKIPPED]');});

    var derived = work.append_map(depend).unique();
    work = work.filter(function(e) { return derived.indexOf(e) == -1;});

    return aspects.test(work, dir);
  }
  ,
  test: function(work, dir, model, filename, baseline) {
    return work.reduce(function(promise, e) {
      return promise.then(function(result1) {
        var modelname = model || path.basename(dir);
        console.log(e + '[' + modelname + '] ...');
        return aspects.test(dependencies[e], dir, model, filename, baseline)
          .then(function(result1) {
            return aspects[e](dir,
                              modelname,
                              filename || dir + '/' + modelname + '.dzn',
                              baseline || (dir + '/baseline/' + e + '/' + modelname))
              .then(function(result2){ return result1 || result2; });
          })
          .then(function(result2) { console.log(e + '[' + modelname + ']: ' + (result2 ? (result2 == 'ERROR' ? '[ERROR]' : '[FAILED]') : '[OK]'));
                                    return result1 || result2; });
      });
    }, q(0));
  }
  ,
triangle: function() {
    return q(0);
  }
  ,
  code: function(dir, model, filename, baseline) {
    var out = __dirname+'/../out/'+path.basename(dir);
    var cmd = 'make CODE=c++ MODEL='+model+' IN='+dir+' OUT='+out+' -f '+__dirname+'/code.make';
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  execute: function(dir, model, filename, baseline) {
    var out = __dirname+'/../out/'+path.basename(dir);
    var trace = dir+'/'+model+'.trace';
    return lstat(trace)
      .then (function(stats) {
        var cmd = out+'/test < '+trace;
        return util.spawn_sync_shell(cmd)
          .fail (function(err) {console.log(err); return 1; });
      })
      .fail (function(err) {
        console.log('execute: [SKIPPED] no trace file');
        return q(0);
      });
  }
  ,
  build: function(dir, model, filename, baseline) {
    var out = __dirname+'/../out/'+path.basename(dir);
    var cmd = 'make OUT='+out+' IN='+out+' -f '+__dirname+'/build.make'
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  convert: function(dir, model, filename, baseline) {
    console.log('convert: [TODO]');
    return q(0);
  }
  ,
  parse: function(dir, model, filename, baseline) {
    var lstat = q.denodeify(fs.lstat);
    return lstat(baseline)
      .then (function(stats) {
        return 'diff -uw '+baseline+' <(dzn -v parse '+filename+' 2>&1)';
      })
      .fail (function(err) {
        return '[ "$(dzn parse '+filename+' 2>&1)" = "" ]';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd)
          .fail (function(err) {console.log(err); return 1; });
      });
  }
  ,
  run: function(dir, model, filename, baseline) {
    console.log('run: [TODO]');
    return q(0);
  }
  ,
  table: function(dir, model, filename, baseline) {
    console.log('table: [TODO]');
    return q(0);
  }
  ,
  tables: function(dir, model, filename, baseline) {
    console.log('tables: [TODO]');
    return q(0);
  }
  ,
  traces: function(dir, model, filename, baseline) {
    var out = __dirname+'/../out/' + path.basename(dir);
    var flush = ''; // TODO: config
    var illegal = ''; // TODO: config
    var cmd =	'dzn traces -q 7 '+illegal+' '+flush+' -m '+model+' -o '+out+' '+filename;
    return lstat(out)
      .fail(function(){return util.spawn_sync_shell('mkdir -p ' + out);})
      .then(function(){return util.spawn_sync_shell(cmd);})
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  verify: function(dir, model, filename, baseline) {
    return lstat(baseline)
      .then (function(stats) {
        return 'diff -uwB '+baseline+' <(dzn --verbose verify --all -m '+model+' '+filename+' | '+__dirname+'/../bin/reorder)';
      })
      .fail (function(err) {
        return '[ "$(dzn verify --all -m '+model+' '+filename+')" = "" ]';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd);
      })
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  view: function(dir, model, filename, baseline) {
    console.log('view: [TODO]');
    return q(0);
  }
  ,
};

module.exports = aspects;
