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
var util = require(__dirname+'/util');
var lstat = q.denodeify(fs.lstat);
var dzn = __dirname + '/../../client/bin/dzn';

var default_meta = 
  { skip: []
  , ignore: []
  , flush: false
  , language: ["c++"]
  };
  
function get_meta(dir) {
  try {
    var meta_string = fs.readFileSync(dir+'/META');
    try {
      var meta = JSON.parse (meta_string);
    } catch (e) {
      console.log('[ERROR]: '+ dir + '/META is not a valid JSON object');
    }
    Object.keys(default_meta).each(function (e) { meta[e] = meta[e] || default_meta[e]; });
    return meta;
  } catch (e) {}
  return default_meta;
}

function skip_filter (meta) {
  return function (e) {
    return (meta.skip.indexOf(e) == -1) || console.log(e + ': [SKIPPED]') && false;
  }
}

var dependencies = {
  build:    ['code'],
  code:     [],
  convert:  [],
  execute:  ['traces', 'build'],
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
    function find_key(v, e) {
      Object.keys(dependencies).indexOf(e) == -1 && console.error(e + ' not listed');
      return v && dependencies[e];
    }

    if(!Object.keys(dependencies)
       .reduce(function(v, e){ return v && dependencies[e].reduce(find_key, true); }, true))
      return q(1);

    return util.spawn_sync_shell(dzn + ' hello')
      .then(function(result) {
        if(result != 0) {
          console.error('dzn hello failed (is your server running?)');
          return result;
        }

        var meta = get_meta (dir);
        work = (work.length == 0 || work[0] == 'all'
                ? Object.keys(dependencies)
                : work)f
          .filter (skip_filter (meta));

        var derived = work.append_map(depend).unique()
            .filter (skip_filter (meta));
        work = work.filter(function(e) { return derived.indexOf(e) == -1;});

        return aspects.test(work, {}, dir, undefined, undefined, undefined, meta).then (function(result) { return result.exitcode; });
      });
  }
  ,
  test: function(work, done, dir, model, filename, baseline, meta) {
    return work
      .filter (skip_filter (meta))
      .reduce(function(promise, e) {
      return promise.then(function(result1) {
        if (done[e]) return result1;
        var modelname = model || path.basename(dir);
        console.log(e + '[' + modelname + '] ...');
        return aspects.test(dependencies[e], result1.done, dir, model, filename, baseline, meta)
          .then(function(result) {
            return result.exitcode && result
              || aspects[e](dir,
                            modelname,
                            filename || dir + '/' + modelname + '.dzn',
                            baseline || (dir + '/baseline/' + e + '/' + modelname),
                            meta)
              .then(function(exitcode){ var done = result.done; done[e] = true; return {exitcode:exitcode, done:done};});
          })
          .then(function(result2) { console.log(e + '[' + modelname + ']: ' + (result2.exitcode ? (result2.exitcode == 'ERROR' ? '[ERROR]' : '[FAILED]') : '[OK]'));
                                    var done = result2.done; done[e] = true;
                                    return {exitcode: result1.exitcode || result2.exitcode, done:done };
                                  });
      });
    }, q({exitcode:0, done:done}));
  }
  ,
  triangle: function() {
    return q(0);
  }
  ,
  code: function(dir, model, filename, baseline) {
    var out = __dirname+'/../out/'+path.basename(dir);
    var cmd = 'make DZN=' + dzn + ' CODE=c++ MODEL='+model+' IN='+dir+' OUT='+out+' -f '+__dirname+'/code.make';
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  build: function(dir, model, filename, baseline) {
    var out = __dirname+'/../out/'+path.basename(dir);
    var cmd = 'make DIR='+dir+' OUT='+out+' IN='+out+' -f '+__dirname+'/build.make'
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
        return 'diff -uw '+baseline+' <(' + dzn + ' -v parse '+filename+' 2>&1)';
      })
      .fail (function(err) {
        return '[ "$(' + dzn + ' parse '+filename+' 2>&1)" = "" ]';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd)
          .fail (function(err) {console.log(err); return 1; });
      });
  }
  ,
  run_traces: function(dir, model, filename, baseline, app) {
    var out = __dirname+'/../out/'+path.basename(dir);

    function ls_files_recursively(dir) {
      return q.denodeify(fs.readdir)(dir)
        .then(function(entries) {
          return q.all(entries.map(function(entry) {
            entry = dir + '/' + entry;
            var is_dir = false;
            try { is_dir = fs.lstatSync(entry).isDirectory(); } catch(e) {}
            return is_dir && ls_files_recursively(entry) || [entry];
          }))
            .then(function(entries) {
              return entries.append_map(util.identity);
            })
        });
    }

    return q.all([ls_files_recursively(dir + '/baseline'),
                  ls_files_recursively(out)]
                 .map(function (e) { return e.fail( function (e) { console.log(baseline + ' ' + e + e.stack); return []; }); }))
      .then(function(files_list) {
        var f = [].concat.apply([],files_list);
          return f.filter(function(file){ return /trace/.exec(file); });
      })
      .then(function(traces) {
        if(traces.length == 0)
          console.log('execute: [SKIPPED] no trace file(s)');
        return traces;
      })
      .then (function(traces) {
        return traces.reduce(function(promise, trace) {
          return promise.then(function(result1){return app(trace).then(function(result2){ return result1 || result2; }); });
        }, q(0))
      });
  }
  ,
  execute: function(dir, model, filename, baseline, meta) {
    var out = __dirname+'/../out/'+path.basename(dir);
    var flush = meta.flush && ' --flush' || '';
    return aspects.run_traces(dir, model, filename, baseline, function(trace){
      return util.spawn_sync_shell(
        'diff -uw '
          + trace
          + ' <(cat '+ trace + ' | ' + out + '/test' + flush
          + '|& ' + __dirname + '/../bin/code2fdr)', 2000)
        .fail (function(err) {console.log('execute fail: ' + err); return 1; });
    });
  }
  ,
  run: function(dir, model, filename, baseline, meta) {
    return aspects.run_traces(dir, model, filename, baseline, function(trace){
      return util.spawn_sync_shell(
        'diff -uw'
          + ' <(grep -v "<flush>" '+ trace + ')'
          + ' <(grep -v "<flush>" '+ trace + '|'
          + ' ' + dzn + ' run --strict --model=' + model + ' ' + filename + ' |&'
          + ' grep -E \'^trace:\' | sed -e \'s,trace:,,\' -e \'s/,/\\n/g\')')
        .fail (function(err) {console.log(err); return 1; });
    });
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
  traces: function(dir, model, filename, baseline, meta) {
    var out = __dirname+'/../out/' + path.basename(dir);
    var flush = meta.flush && ' --flush' || '';
    var illegal = ''; // TODO: config
    var cmd = dzn + ' traces -q 7 '+illegal+flush+' -m '+model+' -o '+out+' '+filename;
    return lstat(out)
      .fail(function(){return util.spawn_sync_shell('mkdir -p ' + out);})
      .then(function(){return util.spawn_sync_shell(cmd);})
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  verify: function(dir, model, filename, baseline) {
    return lstat(baseline)
      .then (function(stats) {
        return 'diff -uwB '+baseline+' <(' + dzn + ' --verbose verify --all -m '+model+' '+filename+' | '+__dirname+'/../bin/reorder)';
      })
      .fail (function(err) {
        return 'out="$(' + dzn + ' verify --all -m '+model+' '+filename+')"; [ "$out" = "" ] || { echo "$out"; false; }';
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
