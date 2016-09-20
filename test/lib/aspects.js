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

var all_languages = require(__dirname+'/languages');
var util = require(__dirname+'/util');
var lstat = q.denodeify(fs.lstat);

function haslanguage(aspect) {
  return (['triangle', 'execute', 'build', 'code'].indexOf(aspect) > -1);
}

function dzn(session) {
  return '../client/bin/dzn --session=' + (session && session || 1);
}

var ext = {c:'.c','c++':'.cc','c++03':'.cc',cs:'.cs',javascript:'.js'};

var default_meta = {
  skip: []
  , ignore: []
  , flush: false
  , languages: all_languages
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

function comment(meta, aspect, language) {
  return meta.comment && (language && meta.comment[language]
                          || meta.comment[aspect]
                          || meta.comment[true]
                          || meta.comment)
    || '';
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

  return q.all(ls_traces('out/'+path.basename(parameters.dir)))
    .then(function(files){return random_selection(files);})
    .fail(function(){return [];})
    .then(function(traces) {
      if (!traces.length) return {status: 1, output: "No traces available"};
      return traces.reduce(function(promise, trace) {
        return promise.then(function(result1){
          return app(trace).then(function(result2){
            return {status: result1.status || result2.status, output: result1.output + result2.output};
          });
        });
      }, q({status:0,output:''}))
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
        if(result.status != 0) {
          console.error('dzn hello failed (is your server running?)');
          return result;
        }
        return util.spawn_sync_shell('mkdir -p out && cp -r ' + dir + ' out')
          .then(function() {
            dir = 'out/' + path.basename(dir);
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
                    return {status: result1.status || result2.status, parameters: result2.parameters}
                  });
                });
              }, q({status:0, parameters:parameters}))
              .then (function(result) {
                var outcome = {status:{},output:{}};
                Object.keys(dependencies).each(function(aspect){
                  if(haslanguage(aspect)) {
                    outcome.status[aspect] = {};
                    all_languages.each(function(language) {
                      outcome.status[aspect][language] = result.parameters.outcome && result.parameters.outcome.status[aspect] && result.parameters.outcome.status[aspect][language] || 'SKIPPED';
                    });
                  } else {
                    outcome.status[aspect] = result.parameters.outcome && result.parameters.outcome.status[aspect] || 'SKIPPED';
                  }
                });

                outcome.output = result.parameters.outcome && result.parameters.outcome.output || '';
                all_languages.each(function(language) {
                  Object.keys(dependencies).each(function(aspect) {
                    if(haslanguage(aspect))
                      outcome.output[aspect + '-' + language] = outcome.output[aspect + '-' + language] || comment(parameters.meta, aspect, language);
                    else
                      outcome.output[aspect] = outcome.output[aspect] || comment(parameters.meta, aspect);
                  });
                });
                return util.spawn_sync_shell('mkdir -p out/' + path.basename(dir))
                  .then(function() {
                    fs.writeFileSync('out/' + path.basename(dir) + '/outcome.json', JSON.stringify(outcome,null,2));
                    return result.status;
                  });
              });
          });
      });
  }
  ,
  test: function(parameters) { // pre: parameters.meta.languages == [ l ]
    var language = parameters.meta.languages[0];

    function updateparameters(parameters, output, aspect, language) {
      parameters.outcome = parameters.outcome || {};
      parameters.outcome.output = parameters.outcome.output || {};
      if(language) {
        parameters.outcome.output[aspect + '-' + language] = output;
      } else {
        parameters.outcome.output[aspect] = output;
      }
      return parameters;
    }

    function testcase(aspect,dependencies,language) {
      if (dependencies.status) {
        return {status: dependencies.status,
                parameters: updateparameters(dependencies.parameters, "Not executed because prerequisite did not succeed", aspect, language)};
      }
      return aspects[aspect](dependencies.parameters)
        .then(function(result) {
          return {status: result.status, parameters: updateparameters(dependencies.parameters, result.output, aspect, language)};
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
      return {status: result1.status || result2.status, parameters: parameters2};
    }
    return parameters.work
      .filter (skip_filter (parameters.meta))
      .reduce(function(promise, aspect) {
        return promise.then(function(result1) {
          if (isdone(result1.parameters.done, aspect, language)) return result1;
          var header = aspect + (haslanguage(aspect) ? '[' + language + ']' : '') + '[' + result1.parameters.model + ']';
          console.log(header + ' ...');
          var parameters1 = util.deep_copy(result1.parameters);
          parameters1.work = dependencies[aspect];
          return aspects.test(parameters1)
            .then(function(result2){return testcase(aspect, result2, haslanguage(aspect) && language);})
            .then(function(result2){
              var status = result2.status ? (result2.status == -1 ? 'ERROR' : 'FAILED') : 'OK';
              result2.parameters.outcome = result2.parameters.outcome || {};
              result2.parameters.outcome.status = result2.parameters.outcome.status || {};
              if(haslanguage(aspect)) {
                result2.parameters.outcome.status[aspect] = result2.parameters.outcome.status[aspect] || {};
                result2.parameters.outcome.status[aspect][language] = status;
              }
              else result2.parameters.outcome.status[aspect] = status;
              console.log(header + '[' + status + ']');
              return result2;
            })
            .then(function(result2){return collect(aspect, result1, result2);});
        });
      }, q({status:0, parameters: parameters}));
  }
  ,
  triangle: function(parameters) {
      return q({status:0, output:''});
  }
  ,
  code: function(parameters) {
    var language = parameters.meta.languages[0];
    var imports = parameters.meta.imports || "";
    var tss = parameters.meta.tss;
    var out = 'out/'+path.basename(parameters.dir)+'/'+language;
    var main = parameters.dir + '/main' + ext[language];
    try {main = fs.lstatSync (main).isFile () && main;} catch (e){main=undefined;};
    var cmd = 'make DZN="' + dzn() + '"'
        + ' IMPORTS=\"'+imports+'\"'
        + ' LANGUAGE='+language
        + ' IN='+parameters.dir
        + ' OUT='+out
        + (main ? ' MAIN='+main:'')
        + (tss ? ' TSS='+tss:'')
        + ' MODEL='+parameters.model
        + ' -f '+'lib/code.make';
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
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
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
  execute: function(parameters) {
    var language = parameters.meta.languages[0];
    var interpreter = {
      goops:'guile',
      javascript:'node',
      python: 'python',
      cs: 'sh',
    }[language] || '';
    var out = 'out/'+path.basename(parameters.dir)+'/'+language;
    var flush = parameters.meta.flush && ' --flush' || '';
    return run_traces(parameters, 'execute', function(trace) {
      var expectation = parameters.dir + '/baseline/execute/' + language + '/expectation';
      try {
        var cmd = 'cat '+ trace + ' | ' + interpreter + ' ' + out + '/test' + flush;
        fs.lstatSync(expectation);
        return util.spawn_sync_shell(
          'timeout 10 diff -uw ' + expectation
            + ' <(set -o pipefail;'
            + cmd
            + ' |& bin/code2fdr'
            + ' || (' + cmd + ' ; echo "E""R""R""O""R"))');
      } catch(e) {
        return util.spawn_sync_shell(
          'timeout 10 diff -uw ' + trace + ' <(set -o pipefail;'
            + cmd
            + ' |& bin/code2fdr'
            + ' || (' + cmd + ' ; echo "E""R""R""O""R"))');
      }
    });
  }
  ,
  convert: function(parameters) {
    var dm = parameters.dir + '/' + parameters.model + '.dm';
    var imports = parameters.meta.imports || "";
    return lstat(dm)
      .then (function(stats) {
        var out = 'out/'+path.basename(parameters.dir);
        var cmd = 'mkdir -p '+out+'; '+
            'echo "'+dm+' -> '+out+'/'+parameters.model+'.dzn"; ' +
            dzn()+' convert -g '+imports+' -o '+out+' '+dm+';'+
            'sed -i -e "s,in void on(),in void on1()," '+out+'/*.dzn';
        return util.spawn_sync_shell(cmd)
          .then (function (result) {
            var parameters1 = util.deep_copy(parameters);
            parameters1.dir = out;
            parameters1.filename = out + '/' +parameters.model+'.dzn';
            return {status:0, parameters:parameters1};
          })
          .fail (function(err) {console.log(err); return {status: -1, output: err}});
      })
      .fail (function(err) {
        var comment = 'convert: [SKIPPED] no DM file '+dm;
        console.log(comment);
        return {status: 0, output: comment};
      });
  }
  ,
  parse: function(parameters) {
    var lstat = q.denodeify(fs.lstat);
    var baseline = parameters.dir + '/baseline/parse/' + parameters.model + '.stderr';
    var imports = parameters.meta.imports || "";

    return lstat(baseline)
      .then (function(stats) {
        return 'diff -uw '+baseline+' <(' + dzn() + ' -v parse '+imports+' '+parameters.filename+' |& sed "s,.\r,,g")';
      })
      .fail (function(err) {
        return '[ "$(' + dzn() + ' parse '+imports+' '+parameters.filename+' |& sed \'s,.\r,,g\')" = "" ]';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd)
          .fail (function(err) {console.log(err); return {status: -1, output: err}});
      });
  }
  ,
  run: function(parameters) {
    return run_traces(parameters, 'run', function(trace){
      var model = parameters.meta.model || parameters.model;
      var imports = parameters.meta.imports || "";
      return util.spawn_sync_shell(
        'diff -uw'
          + ' <(grep -v "<flush>" '+ trace + ')'
          + ' <(grep -v "<flush>" '+ trace + '|'
          + ' ' + dzn(parameters.session) + ' run '+imports+' --strict --model=' + model + ' ' + parameters.filename + ' |&'
          + ' grep -E \'^trace:\' | sed -e \'s,trace:,,\' -e \'s/,/\\n/g\')')
        .fail (function(err) {console.log(err); return {status: -1, output: err}});
    });
  }
  ,
  table: function(parameters) {

    function test_table(promise, args) {
      var suffix = args[0];
      var form = args[1];
      return promise.then(function(result1) {
        var baseline = parameters.dir + '/baseline/table/'+parameters.model+ '-' + form + '.' + suffix;
        return lstat(baseline)
          .then (function(stats) {
            var imports = parameters.meta.imports || "";
            var cmd = 'diff -uwB '+baseline+' <('+dzn()+' table '+imports+' --form=' + form + ' -o - '+parameters.filename + (suffix == 'html' ? '| w3m -dump -T text/html' : '') +')';
            return util.spawn_sync_shell(cmd)
              .fail (function(err) {console.log(err); return {status: -1, output: result.output + err}});
          })
          .then (function(result2) { return {status: result1.status || result2.status, output: result1.output + result2.output}; })
          .fail (function(err) {
            const comment = 'table: [SKIPPED] no baseline '+baseline;
            console.log(comment);
            return {status: result1.status, output: result1.output + comment};
          });
      });
    }

    return [['dzn','state'],
            ['dzn','event'],
            ['html','state'],
            ['html','event']].reduce(test_table, q({status:0, output:''}));
  }
  ,
  traces: function(parameters) {
    var out = 'out/' + path.basename(parameters.dir);
    var flush = parameters.meta.flush ? ' --flush' : '';
    var illegal = ''; // TODO: config
    var imports = parameters.meta.imports || "";
    var cmd = dzn() + ' traces '+imports+' -q 7 '+illegal+flush+' -m '+parameters.model+' -o '+out+' '+parameters.filename;
    return lstat(out)
      .fail(function(){return util.spawn_sync_shell('mkdir -p ' + out);})
      .then(function(){return util.spawn_sync_shell(cmd);})
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
  verify: function(parameters) {
    var baseline = parameters.dir + '/baseline/verify/' + parameters.model;
    var dir = 'out/' + path.basename(parameters.dir)
    var out = dir + '/'+parameters.model;
    var err = out + '.stderr';
    var imports = parameters.meta.imports || "";
    return lstat (baseline)
      .then (function(stats) {
        return 'mkdir -p '+dir+';'
          + '{ set -o pipefail;'
          + dzn(parameters.session)
          + ' --verbose verify --all --model='+parameters.model
          + ' '+imports
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
        return 'out="$(' + dzn(parameters.session) + ' verify --all -m '+parameters.model
          + ' '+imports
          + ' '+parameters.filename
          + ' 2>&1)" && [ "$out" = "" ] || { echo "verification output: \"$out\""; false; }';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd);
      })
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
  view: function(parameters) {
    var baseline = parameters.dir + '/baseline/verify/' + parameters.model;
    var dir = 'out/' + path.basename(parameters.dir)
    var out = dir + '/'+parameters.model;
    var err = out + '.stderr';
    var imports = parameters.meta.imports || "";

    var cmd = dzn() + ' view '+imports+' '+parameters.filename;
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
};

module.exports = aspects;
