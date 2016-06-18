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

var languages = require(__dirname+'/languages');
var util = require(__dirname+'/util');
var lstat = q.denodeify(fs.lstat);

function dzn(session) {
  return '../client/bin/dzn --session=' + (session && session || 1);
}

var ext = {c:'.c','c++':'.cc',javascript:'.js'};

var default_meta = {
  skip: []
  , ignore: []
  , flush: false
  , languages: languages
  , max: {code:undefined,run:50}
};

var session_counter = 0;

function read_meta(dir, default_meta) {
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

var dependencies = {
  build:    ['code'],
  code:     ['convert'],
  convert:  [],
  execute:  ['traces', 'build'],
  parse:    ['convert'],
  run:      ['traces'],
  table:    ['convert'],
  traces:   ['convert'],
  triangle: ['execute', 'run'],
  verify:   ['convert'],
  view:     ['convert'],
};

function depend(e) {
  return dependencies[e].concat(dependencies[e].append_map(depend));
}

function skip_filter (meta) {
  function filter_aspect(e) {
    return meta.skip.indexOf(e) == -1;
  }
  function filter_dependency(e) {
    return depend(e).filter(function(a) { return meta.skip.indexOf(a) != -1; }).length == 0;
  }
  return function (e) {
    var language = meta.languages.length === 1 && meta.languages[0];
    if(!language || meta.skip.indexOf(language) == -1) {
      if(Object.keys(dependencies).indexOf(e) == -1) return true;
      if(filter_aspect(e) && filter_dependency(e)) return true;
    }
    var comment = language && meta.comment[language]
        || meta.comment[e]
        || meta.comment[true]
        || meta.comment
        || '';
    console.log(e + ': [SKIPPED] ' + comment);
    return false;
  }
}

function run_traces(parameters, asp, app) {

  function ls_traces(dir) {
    return q.denodeify(fs.readdir)(dir)
      .then(function(entries) {
        return entries
          .filter(function(entry) {return /trace/.test(entry);})
          .map(function(entry){ return dir + '/' + entry; });
      });
  }

  function random_selection(files) {
    if (parameters.meta.max && parameters.meta.max[asp] !== undefined) {
      var lower = Math.max(Math.floor ((files.length - parameters.meta.max[asp]) * Math.random ()), 0);
      files = files.slice (lower, lower + parameters.meta.max[asp]);
    }
    return files;
  }

  return q.all([q.all(ls_traces(parameters.dir)),
                q.all(ls_traces('out/'+path.basename(parameters.dir))).then(function(files){return random_selection(files);})]
               .map(function (e) { return e.fail( function (e) { return []; }); }))
    .then(function(files_list) {
      return [].concat.apply([],files_list);
    })
    .then(function(traces) {
      if (!traces.length) throw new Error ('run_traces: no traces found');
      return traces.reduce(function(promise, trace) {
        return promise.then(function(result1){return app(trace).then(function(result2){ return result1 || result2; }); });
      }, q(0))
    });
}

var aspects = {
  list: function(){
    return Object.keys(dependencies);
  }
  ,
  all: function(session, work, languages, dir) {

    function find_key(v, e) {
      Object.keys(dependencies).indexOf(e) == -1 && console.error(e + ' not listed');
      return v && dependencies[e];
    }

    if(!Object.keys(dependencies)
       .reduce(function(v, e){ return v && dependencies[e].reduce(find_key, true); }, true))
      return q(1);

    return util.spawn_sync_shell(dzn(session) + ' hello')
      .then(function(result) {
        if(result != 0) {
          console.error('dzn hello failed (is your server running?)');
          return result;
        }

        var meta = read_meta (dir, default_meta);
        meta.languages = languages.length && languages || meta.languages;

        work = (work.length == 0
                ? Object.keys(dependencies)
                : work)
          .filter (skip_filter (meta));

        var derived = work.append_map(depend).unique()
            .filter (skip_filter (meta));
        work = work.filter(function(e) { return derived.indexOf(e) == -1;});

        var modelname = path.basename(dir);
        var filename = dir + '/' + modelname + '.dzn';
        var parameters = {work: work, done: {}, dir: dir, model: modelname, filename: filename, meta: meta, session: session};
        return meta.languages
          .filter (skip_filter (meta))
          .reduce(function(promise, language) {
          return promise.then(function(result1) {
            var parameters = util.deep_copy(result1.parameters);
            parameters.meta.languages = [ language ];
            parameters.work = work;
            return aspects.test(parameters).then (function(result2) {
              return {exitcode: result1.exitcode || result2.exitcode, parameters: result2.parameters}
            });
          });
        }, q({exitcode:0, parameters:parameters}))
        .then (function(result) { return result.exitcode; });
      });
  }
  ,
  test: function(parameters) { // pre: parameters.meta.languages == [ l ]
    var language = parameters.meta.languages[0];

    function haslanguage(aspect) {
      return (['triangle', 'execute', 'build', 'code'].indexOf(aspect) > -1);
    }

    function testcase(aspect,result1) {
      return result1.exitcode && result1
        || aspects[aspect](result1.parameters)
        .then(function(result2) {
          return (typeof(result2) == 'number') ? {exitcode: result2, parameters: result1.parameters} : result2;
        });
    }

    function isdone(done, aspect, language) {
      return haslanguage(aspect) ? (done[aspect] && done[aspect][language]) : done[aspect];
    }

    function setdone(done, aspect, language) {
      if (haslanguage(aspect)) {
        done[aspect] = done[aspect] || {};
        done[aspect][language] = true;
      }
      else done[aspect] = true;
      return done;
    }

    function collect(aspect, result1, result2) {
      var parameters2 = util.deep_copy(result2.parameters);
      parameters2.done = setdone(parameters2.done, aspect, language);
      return {exitcode: result1.exitcode || result2.exitcode, parameters: parameters2};
    }
    return parameters.work
      .filter (skip_filter (parameters.meta))
      .reduce(function(promise, e) {
        return promise.then(function(result1) {
          if (isdone(result1.parameters.done, e, language)) return result1;
          var header = e + (haslanguage(e) ? '[' + language + ']' : '') + '[' + result1.parameters.model + ']';
          console.log(header + ' ...');
          var parameters1 = util.deep_copy(result1.parameters);
          parameters1.work = dependencies[e];
          return aspects.test(parameters1)
            .then(function(result1){return testcase(e, result1);})
            .then(function(result2){
              console.log(header + (result2.exitcode ? (result2.exitcode == -1 ? '[ERROR]' : '[FAILED]') : '[OK]'));
              return result2;
            })
            .then(function(result2){return collect(e, result1, result2);});
        });
      }, q({exitcode:0, parameters: parameters}));
  }
  ,
  triangle: function(parameters) {
    return q(0);
  }
  ,
  code: function(parameters) {
    var language = parameters.meta.languages[0];
    var out = 'out/'+path.basename(parameters.dir)+'/'+language;
    var main = parameters.dir + '/main' + ext[language];
    try {main = fs.lstatSync (main).isFile () && main;} catch (e){main=undefined;};
    var cmd = 'make DZN="' + dzn() + '"'
        + ' LANGUAGE='+language
        + ' IN='+parameters.dir
        + ' OUT='+out
        + (main ? ' MAIN='+main:'')
        + ' MODEL='+parameters.model
        + ' -f '+'lib/code.make';
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  build: function(parameters) {
    var language = parameters.meta.languages[0];
    var out = 'out/'+path.basename(parameters.dir)+'/'+language;
    var main = parameters.dir + '/main' + ext[language];
    try {main = fs.lstatSync (main).isFile () && main;} catch (e){main=undefined;};
    var cmd = 'make DIR='+parameters.dir
        + ' LANGUAGE='+language
        + ' OUT='+out
        + ' IN='+out
        + (main ? ' MAIN='+main : '')
        + ' -f '+'lib/build.' + language + '.make';
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  execute: function(parameters) {
    var language = parameters.meta.languages[0];
    var out = 'out/'+path.basename(parameters.dir)+'/'+language;
    var flush = parameters.meta.flush && ' --flush' || '';
    return run_traces(parameters, 'execute', function(trace) {
      var expectation = parameters.dir + '/baseline/execute/' + language + '/expectation';
      try {
        fs.lstatSync(expectation);
        return util.spawn_sync_shell('diff -uw ' + expectation + ' <(set -o pipefail; cat '+ trace + ' | ' + out + '/test' + flush + ' |& bin/code2fdr || echo ERROR)');
      } catch(e) {
        return util.spawn_sync_shell('diff -uw ' + trace + ' <(set -o pipefail; cat '+ trace + ' | ' + out + '/test' + flush + ' |& bin/code2fdr)')
      }
    });
  }
  ,
  convert: function(parameters) {
    var dm = parameters.dir + '/' + parameters.model + '.dm';
    return lstat(dm)
      .then (function(stats) {
        var out = 'out/'+path.basename(parameters.dir);
        var cmd = 'mkdir -p '+out+'; '+
            'echo "'+dm+' -> '+out+'/'+parameters.model+'.dzn"; ' +
            dzn()+' convert -g -o '+out+' '+dm+'; ' +
            'sed -i -e "s,\\(component \\w*\\)Comp,\\1," -e "s,Iasd.builtin.ITimer,ITimer," '+out+'/'+parameters.model+'Comp.dzn; ' +
            'sed -i -e "s,in void on(),in void on1()," '+out+'/*.dzn; ' +
            'mv '+out+'/'+parameters.model+'Comp.dzn '+out+'/'+parameters.model+'.dzn'
        return util.spawn_sync_shell(cmd)
          .then (function (result) {
            var parameters1 = util.deep_copy(parameters);
            parameters1.dir = out;
            parameters1.filename = out + '/' +parameters.model+'.dzn';
            return {exitcode:0, parameters:parameters1};
          })
          .fail (function(err) {console.log(err); return 1; });
      })
      .fail (function(err) {
        console.log ('convert: [SKIPPED] no DM file '+dm);
        return 0;
      });
  }
  ,
  parse: function(parameters) {
    var lstat = q.denodeify(fs.lstat);
    var baseline = parameters.dir + '/baseline/parse/' + parameters.model;

    return lstat(baseline)
      .then (function(stats) {
        return 'diff -uw '+baseline+' <(' + dzn() + ' -v parse '+parameters.filename+' 2>&1)';
      })
      .fail (function(err) {
        return '[ "$(' + dzn() + ' parse '+parameters.filename+' 2>&1)" = "" ]';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd)
          .fail (function(err) {console.log(err); return 1; });
      });
  }
  ,
  run: function(parameters) {
    return run_traces(parameters, 'run', function(trace){
      var model = parameters.meta.model || parameters.model;
      return util.spawn_sync_shell(
        'diff -uw'
          + ' <(grep -v "<flush>" '+ trace + ')'
          + ' <(grep -v "<flush>" '+ trace + '|'
          + ' ' + dzn(parameters.session) + ' run --strict --model=' + model + ' ' + parameters.filename + ' |&'
          + ' grep -E \'^trace:\' | sed -e \'s,trace:,,\' -e \'s/,/\\n/g\')')
        .fail (function(err) {console.log(err); return 1; });
    });
  }
  ,
  table: function(parameters) {
    return q(0)
      .then (function(result) {
        var baseline = parameters.dir + '/baseline/table/'+parameters.model+'-state.dzn';
        return lstat(baseline)
          .then (function(stats) {
            var cmd = 'diff -uwB '+baseline+' <('+dzn()+' table --form=state -o - '+parameters.filename+')';
            return util.spawn_sync_shell(cmd)
              .fail (function(err) {console.log(err); return 1; });
          })
          .then (function(result1) { return result || result1; })
          .fail (function(err) {
            console.log('table: [SKIPPED] no baseline '+baseline);
            return 0;
          });
      })
      .then (function(result) {
        var baseline = parameters.dir + '/baseline/table/'+parameters.model+'-event.dzn';
        return lstat(baseline)
          .then (function(stats) {
            var cmd = 'diff -uwB '+baseline+' <('+dzn()+' table --form=event -o - '+parameters.filename+')';
            return util.spawn_sync_shell(cmd)
              .fail (function(err) {console.log(err); return 1; });
          })
          .then (function(result1) { return result || result1; })
          .fail (function(err) {
            console.log('table: [SKIPPED] no baseline '+baseline);
            return result;
          });
      })
      .then (function(result) {
        var baseline = parameters.dir + '/baseline/table/'+parameters.model+'-state.html';
        return lstat(baseline)
          .then (function(stats) {
            var cmd = 'diff -uwB '+baseline+' <('+dzn()+' --html table --form=state -o - '+parameters.filename+' | w3m -dump -T text/html)';
            return util.spawn_sync_shell(cmd)
              .fail (function(err) {console.log(err); return 1; });
          })
          .then (function(result1) { return result || result1; })
          .fail (function(err) {
            console.log('table: [SKIPPED] no baseline '+baseline);
            return result;
          });
      })
      .then (function(result) {
        var baseline = parameters.dir + '/baseline/table/'+parameters.model+'-event.html';
        return lstat(baseline)
          .then (function(stats) {
            var cmd = 'diff -uwB '+baseline+' <('+dzn()+' --html table --form=event -o - '+parameters.filename+' | w3m -dump -T text/html)';
            return util.spawn_sync_shell(cmd)
              .fail (function(err) {console.log(err); return 1; });
          })
          .then (function(result1) { return result || result1; })
          .fail (function(err) {
            console.log('table: [SKIPPED] no baseline '+baseline);
            return result;
          });
      })
  }
  ,
  traces: function(parameters) {
    var out = 'out/' + path.basename(parameters.dir);
    var flush = parameters.meta.flush ? ' --flush' : '';
    var illegal = ''; // TODO: config
    var cmd = dzn() + ' traces -q 7 '+illegal+flush+' -m '+parameters.model+' -o '+out+' '+parameters.filename;
    return lstat(out)
      .fail(function(){return util.spawn_sync_shell('mkdir -p ' + out);})
      .then(function(){return util.spawn_sync_shell(cmd);})
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  verify: function(parameters) {
    var baseline = parameters.dir + '/baseline/verify/' + parameters.model;
    var dir = 'out/' + path.basename(parameters.dir)
    var out = dir + '/'+parameters.model;
    var err = out + '.stderr';
    return lstat (baseline)
      .then (function(stats) {
        return 'mkdir -p '+dir+';'
          + '{ set -o pipefail;'
          + dzn(parameters.session)
          + ' --verbose verify --all --model='+parameters.model
          + ' '+parameters.filename
          + ' 2>'+err
          + '| bin/reorder > '+out
          + ';}'
          + ' || (diff -uw '+baseline+' '+out
          + '     && (test ! -s '+err
          + '         || sed -i s,.\r,,g '+err+';'
          + '            diff -u '+baseline+'.stderr '+err+'))';
      })
      .fail (function(err) {
        console.log ('verify: no baseline=' + baseline);
        return 'out="$(' + dzn(parameters.session) + ' verify --all -m '+parameters.model+' '+parameters.filename+' 2>&1)" && [ "$out" = "" ] || { echo "verification output: \"$out\""; false; }';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd);
      })
      .fail (function(err) {console.log(err); return 1; });
  }
  ,
  view: function(parameters) {
    console.log('view: [TODO]');
    return q(0);
  }
  ,
};

module.exports = aspects;
