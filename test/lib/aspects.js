// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
// Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2016, 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
  return (['triangle', 'execute', 'build', 'code'].indexOf(aspect.split ('_')[0]) > -1);
}

function dzn(session) {
  return 'timeout 30 '
    + (process.env['DZN'] || ( __dirname + '/../../dzn/bin/dzn') + ' --session=' + (session && session || 100));
}

var ext = {c:'.c','c++':'.cc','c++03':'.cc','c++-msvc11':'.cc',cs:'.cs',javascript:'.js'};

var default_meta = {
  skip: []
  , known: []
  , ignore: []
  , flush: false
  , languages: all_languages.filter (function (x) {return x != 'c++-msvc11';})
  , versions: []
  , max: {code:undefined,run:50}
};

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

function has_main(dir, language) {
  var main = dir + '/main' + ext[language];
  try {main = (fs.lstatSync (main).isFile () || fs.lstatSync (main).isSymbolicLink ()) && main;} catch (e){main=undefined;};
  if(!main) {
    main = dir + '/' + language + '/main' + ext[language];
    try {main = (fs.lstatSync (main).isFile () || fs.lstatSync (main).isSymbolicLink ()) && main;} catch (e){main=undefined;};
  }
  return main;
}

function query_versions() {
    var versions = require ('child_process')
        .spawnSync ('bash', ['-c', dzn () + ' query'], {stdio:'pipe'})
        .stdout.toString ()
        .trim ()
        .split ('\n')
        .map (function (s){return s.trim();});
  var default_version = versions.find (function (s){return s[0] == '*'}).slice (2);
  //console.log ('default_version=%j', default_version);

  var extra_versions = versions.filter (function (s){return s[0] != '*'})
      .reverse ();
  //console.log ('extra_versions=%j', extra_versions);

  return [default_version].concat(extra_versions);
}

// function query_versions() {
//   return ['2.4.1'];
// }


var dependencies = {
  convert:  [],
  parse:    ['convert'],
  verify:   ['convert'],
  traces:   ['convert'],
  code:     ['convert'],
  build:    ['code'],
  execute:  ['traces', 'build'],
  run:      ['traces'],
  triangle: ['execute', 'run'],
};

function code_version (v) {return v.replace (/[.]/g, '_');}

var default_aspects = Object.keys(dependencies).filter (function (e) {return ['table','view'].indexOf (e) == -1;});

function depend(e) {
  var deps = dependencies[e] || ['convert'];
  return deps.concat(deps.append_map(depend));
}

function comment(meta, aspect, version, language) {
  return meta.comment && (language && meta.comment[language]
                          || meta.comment[aspect]
                          || meta.comment[true]
                          || meta.comment)
    || '';
}

function imports_string (imports) {
  return (imports || []).map (function (o){return '-I \'' + o.replace (/^all\//, fs.realpathSync (__dirname + '/../all') + '/') + '\'';}).join (' ');
}

function ordered_dependencies() {
  var result = [];
  function add_dependencies(aspect) {
    if (result.indexOf(aspect) == -1) {
      dependencies[aspect].forEach(function(dep) {
        add_dependencies(dep);
      });
      result.push(aspect);
    }
  }
  var order = ['parse', 'verify', 'triangle'];
  order.forEach(function(aspect) {
    add_dependencies(aspect);
  });
  return result;
}

function no_skip_p (meta, version) {
  function dependencies_skipped_p(aspect, language) {
    var deps = depend(aspect) || [];
    var skipped_deps = deps.filter(function(a) { return aspect_in_dict (meta.skip, a, version, language); });
    return skipped_deps.length == 0;
  }

  return function (aspect) {
    var language = meta.languages.length === 1 && meta.languages[0];
    return !aspect_in_dict (meta.skip, aspect, version, language)
        && (Object.keys(dependencies).indexOf(aspect) == -1
            || dependencies_skipped_p (aspect, language));
  }
}

function known (meta, aspect, version, language) {
  return aspect_in_dict (meta.known, aspect, version, language);
}

function aspect_in_dict (dict, aspect, version, language) {
  // dict has?
  // c++, c++:code, code
  // c++<2.8.0, c++:code<2.8.0, code<2.8.0
  // c++>=2.8.0, c++:code>=2.8.0, code>=2.8.0
  // c++=2.8.0, c++:code=2.8.0, code=2.8.0

  function hulp (key) {
    return dict.find (function (term) {
      if (term == key) return true;
      var operator = ['<', '>=', '==', '='].find (function (o) {return term.indexOf (o) != -1;});
      if (version && operator) {
        var a = term.split (operator);
        var t = a[0];
        var v = a.length == 2 && a[1];

        var c = v && util.version_compare (version, v);
        function compare () {
          if (operator == '<') return c < 0;
          if (operator == '=') return c == 0;
          if (operator == '==') return c == 0;
          if (operator == '>=') return c >= 0;
        }
        return (v && t == key && compare ());
      }
      return false;
    });
  }
  return ((language && (hulp (language)
                        || hulp (language+':'+aspect)))
          || hulp (aspect));
}

function ls_traces(dir) {
  return q.denodeify(fs.readdir)(dir)
    .then(function(entries) {
      return entries
        .filter(function(entry) {return /trace/.test(entry);})
        .map(function(entry){ return dir + '/' + entry; });
    });
}

function run_traces(parameters, asp, app) {

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
      }, q({status:0, output:''}))
    });
}

var supported_languages = {
  'default': ['c++', 'c++03', 'c++-msvc11', 'c', 'cs', 'javascript'],
  '2.4.1' : ['c++', 'c++03', 'c++-msvc11', 'c', 'cs', 'javascript'],
};

var aspects = {
  list: function() {
    return Object.keys(dependencies);
  }
  ,
  empty_outcome: function() {
    function nolanguages() {
      var result = {};
      query_versions().each ( function(version) {
        result[version] = {};
        all_languages.each ( function(lan) {
          result[version][lan] = 'NOLOG';
        });
      });
      return result;
    }
    var order = ordered_dependencies();
    var status = {};
    order.each(function(aspect) {
      status[aspect] = haslanguage(aspect) ? nolanguages() : 'NOLOG';
    });
    var result = {status: status, output: {}, order: order};
    return result;
  }
  ,
  all: function(session, work, languages, dir) {
    var startTime = new Date();

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
        default_meta.versions = query_versions();

        return util.spawn_sync_shell('mkdir -p out'
                                     + ' && rm -rf "out/' + path.basename (dir) + '"'
                                     + ' && cp -as --no-preserve=mode,ownership "' + path.resolve (dir) + '" $PWD/out')
          .then(function() {
            dir = 'out/' + path.basename(dir);
            var meta = read_meta (dir, default_meta);
            meta.languages = languages.length && languages || meta.languages;

            work = (work.length == 0
                    ? default_aspects
                    : work);

            var derived = work.append_map(depend).unique();
            work = work.filter(function(e) { return derived.indexOf(e) == -1;});

            var modelname = path.basename(dir);
            var filename = dir + '/' + modelname + '.dzn';
            var parameters = {work: work, done: {}, dir: dir, model: modelname, filename: filename, meta: meta, session: session};
            return meta.versions
              .reduce(function(promise, version) {
                return promise.then(function(result0) {
                  var parameters0 = util.deep_copy(result0.parameters);
                  parameters0.meta.versions = [ version ];
                  return meta.languages
                    .filter (function(language) {
                      return (supported_languages[version] || supported_languages['default']).indexOf(language) != -1;
                    })
                    .reduce(function(promise, language) {
                      return promise.then(function(result1) {
                        var parameters1 = util.deep_copy(result1.parameters);
                        parameters1.meta.languages = [ language ];
                        parameters1.work = work;
                        return aspects.test(parameters1).then (function(result2) {
                          return {status: result1.status || result2.status, parameters: result2.parameters}
                        });
                      });
                    }, q({status:0, parameters:parameters0}));
                });

              }, q({status:0, parameters:parameters}))

              .then (function(result) {
                var endTime = new Date();
                var elapsed = util.elapsedTime(startTime, endTime, true);
                var outcome = {elapsed:elapsed, status:{}, output:{}, order:ordered_dependencies()};
                Object.keys(dependencies).each(function(aspect) {
                  if(haslanguage(aspect)) {
                    outcome.status[aspect] = {};
                    default_meta.versions.each(function(version) {
                      outcome.status[aspect][version] = {};
                      all_languages.each(function(language) {
                        outcome.status[aspect][version][language] = (result.parameters.outcome && result.parameters.outcome.status[aspect] && result.parameters.outcome.status[aspect][version] && result.parameters.outcome.status[aspect][version][language]) || 'SKIPPED';
                      });

                    });

                  } else {
                    outcome.status[aspect] = (result.parameters.outcome && result.parameters.outcome.status[aspect]) || 'SKIPPED';
                  }
                });

                outcome.output = result.parameters.outcome && result.parameters.outcome.output || '';
                default_meta.versions.each(function(version) {
                  all_languages.each(function(language) {
                    Object.keys(dependencies).each(function(aspect) {
                      if(haslanguage(aspect))
                        outcome.output[aspect + '-' + version + '-' + language] = outcome.output[aspect + '-' + version + '-' + language] || comment(parameters.meta, aspect, version, language);
                      else
                        outcome.output[aspect] = outcome.output[aspect] || comment(parameters.meta, aspect);
                    });
                  });
                });
                return util.spawn_sync_shell('mkdir -p "out/' + path.basename(dir) + '"')
                  .then(function() {
                    //fs.writeFileSync('"out/' + path.basename(dir) + '/outcome.json"', JSON.stringify(outcome, null, 2));
                    fs.writeFileSync('out/' + path.basename(dir) + '/outcome.json', JSON.stringify(outcome, null, 2));
                    return result.status;
                  });
              });
          });
      });
  }
  ,
  test: function(parameters) { // pre: parameters.meta.languages == [ l ]
    var version = parameters.meta.versions[0];
    var language = parameters.meta.languages[0];

    function updateparameters(parameters, output, aspect, version, language) {
      parameters.outcome = parameters.outcome || {};
      parameters.outcome.output = parameters.outcome.output || {};
      if(language) {
        parameters.outcome.output[aspect + '-' + version + '-' + language] = output;
      } else {
        parameters.outcome.output[aspect] = output;
      }
      return parameters;
    }

    function setstatus(outcome, aspect, version, language, status) {
      outcome.status = outcome.status || {};
      if(haslanguage(aspect)) {
        outcome.status[aspect] = outcome.status[aspect] || {};
        outcome.status[aspect][version] = outcome.status[aspect][version] || {};
        status = outcome.status[aspect][version][language] || status;
        outcome.status[aspect][version][language] = status;
      }
      else {
        status = outcome.status[aspect] || status;
        outcome.status[aspect] = status;
      }
    }

    function getstatus(outcome, aspect, version, language) {
      var status = 'UNKNOWN';
      if (outcome.status) {
        if(haslanguage(aspect)) {
          if (outcome.status[aspect] && outcome.status[aspect][version] && outcome.status[aspect][version][language])
            status = outcome.status[aspect][version][language];
        }
        else {
          if (outcome.status[aspect])
            status = outcome.status[aspect];
        }
      }
      return status;
    }

    function testcase(aspect, prevresult, version, language, retry) {
      retry = 0; //retry === undefined && 2 || retry;
      if(prevresult.parameters.meta.known)
      {
        if(prevresult.parameters.meta.known[aspect]) retry = 0;
        if(prevresult.parameters.meta.known[version]) retry = 0;
        if(prevresult.parameters.meta.known[aspect + ':' + language]) retry = 0;
        if(prevresult.parameters.meta.known[aspect + ':' + version + ':' + language]) retry = 0;
        if(prevresult.parameters.meta.known[language + ':' + aspect]) retry = 0;
        if(prevresult.parameters.meta.known[version + ':' + language + ':' + aspect]) retry = 0;
      }
      if (prevresult.status) {
        var result = {status: prevresult.status,
                      parameters: updateparameters(prevresult.parameters, "Not executed because prerequisite did not succeed", aspect, version, language)};
        setstatus(result.parameters.outcome, aspect, version, language, 'SKIPPED');
        return result;
      }
      return aspects[aspect](prevresult.parameters)
        .then(function(result) {
          if(result.status && retry) {
            var msg = '[RETRY] ' + prevresult.parameters.filename + ' : ' + (2 - retry);
            console.log (msg);
            return testcase(aspect, prevresult, version, language, retry-1).then(function(o){o.output += msg + '\n'; return o;});
          }
          return {status: result.status, parameters: updateparameters(prevresult.parameters, result.output, aspect, version, language)};
        });
    }

    function isdone(done, aspect, version, language) {
      return haslanguage(aspect) ? (done[aspect] && done[aspect][version] && done[aspect][version][language]) : done[aspect];
    }

    function setdone(done, aspect, version, language) {
      if (haslanguage(aspect)) {
        done[aspect] = done[aspect] || {};
        done[aspect][version] = done[aspect][version] || {};
        done[aspect][version][language] = true;
      }
      else done[aspect] = true;
      return done;
    }

    function collect(aspect, result1, result2) {
      var parameters2 = util.deep_copy(result2.parameters);
      parameters2.done = setdone(parameters2.done, aspect, version, language);
      return {status: result1.status || result2.status, parameters: parameters2};
    }

    return parameters.work
      .reduce(function(promise, aspect) {

        return promise.then(function(result1) {
          if (isdone(result1.parameters.done, aspect, version, language)) {
            var status = getstatus(result1.parameters.outcome, aspect, version, language);
            st = (status == 'ERROR') ? -1 : (status == 'KNOWN' || status  == 'FAILED') ? 1 : 0;
            return {status: st, parameters: result1.parameters};
          }
          var parameters1 = util.deep_copy(result1.parameters);
          parameters1.work = dependencies[aspect] || [];
          return aspects.test(parameters1)
            .then(function(result2){
              if (no_skip_p (result2.parameters.meta, version) (aspect))
                return testcase(aspect, result2, haslanguage(aspect) && version, haslanguage(aspect) && language);

              if(haslanguage(aspect)) {
                result2.parameters.outcome.status[aspect] = result2.parameters.outcome.status[aspect] || {};
                result2.parameters.outcome.status[aspect][version] = result2.parameters.outcome.status[aspect][version] || {};
                result2.parameters.outcome.status[aspect][version][language] = 'SKIPPED';
              }
              else
                result2.parameters.outcome.status[aspect] = 'SKIPPED';

              return {status: 0, parameters: result2.parameters};


            })
            .then(function(result2){
              var knwn = known(result2.parameters.meta, aspect, version, language);
              var status = result2.status ? (result2.status == -1 ? 'ERROR' : (knwn ? 'KNOWN' : 'FAILED')) : (knwn ? 'SOLVED' : 'OK');
              result2.parameters.outcome = result2.parameters.outcome || {};
              setstatus(result2.parameters.outcome, aspect, version, language, status);

              result2.parameters.outcome.status = result2.parameters.outcome.status || {};
              if(haslanguage(aspect)) {
                result2.parameters.outcome.status[aspect] = result2.parameters.outcome.status[aspect] || {};
                result2.parameters.outcome.status[aspect][version] = result2.parameters.outcome.status[aspect][version] || {};
                status = result2.parameters.outcome.status[aspect][version][language] || status;
                result2.parameters.outcome.status[aspect][version][language] = status;
              }
              else {
                status = result2.parameters.outcome.status[aspect] || status;
                result2.parameters.outcome.status[aspect] = status;
              }

              var lang_length = 0;
              var longest_aspect = 9; //longest name for aspect is triangle
              var longest_status = 7; //longest status indication is SKIPPED
              for(i = 0; i < all_languages.length; i++)
                lang_length = all_languages[i].length > lang_length ? all_languages[i].length : lang_length;

              var update = 'update:' + '\t[' + status + ']' + ' '.repeat(longest_status - status.length) ;
              update += ' '+aspect + ' '.repeat(longest_aspect - aspect.length);
              if(haslanguage(aspect)) update += '[' + String(version).substring(0,7) + ']' + (version.length <= 7 ? '.'.repeat(7-version.length) : '') + '[' + language + ']' + '.'.repeat(lang_length - language.length);
              else update += '.'.repeat(lang_length + 11);
              update += ' '+result1.parameters.model;
              console.log(update);
              return result2;
            })
            .then(function(result2) { return collect(aspect, result1, result2); });
        });
      }, q({status:0, parameters: parameters}));
  }
  ,
  triangle: function(parameters) {
      return q({status:0, output:''});
  }
  ,
  code: function(parameters) {
    var version = parameters.meta.versions[0];
    var language = parameters.meta.languages[0];
    var language_dir = parameters.dir + '/' + parameters.meta.languages[0];
    var model = parameters.meta.model || parameters.model;
    // METAs `model' is used for component/system tricksery
    model = parameters.model;
    var imports = imports_string ([parameters.dir, language_dir].concat(parameters.meta.imports || []));
    var code_options = parameters.meta.code_options || "";
    var tss = parameters.meta.tss;
    var main = has_main(parameters.dir, language);
    var out = '"out/'+path.basename(parameters.dir)+'"/'
        + version + '/'
        + language;
    var cmd = 'make'
        + ' DZN="' + dzn() + '"'
        + ' VERSION="'+version+'"'
        + ' IMPORTS=\"'+imports+'\"'
        + ' CODE_OPTIONS=\"'+code_options+'\"'
        + ' LANGUAGE='+language
        + ' IN="'+parameters.dir+'"'
        + ' OUT='+out
        + (main ? ' MAIN='+main:'')
        + (tss ? ' TSS='+tss:'')
        + ' MODEL="'+model+'"'
        + ' -f '+ __dirname + '/code.make';
    return util.spawn_sync_shell(cmd)
    //.fail (function(err) {console.log(err); return {status: -1, output: err}});
      .fail (function(err) {console.log (err.stack); return {status: -1, output: err.stack}});
  }
  ,
  build: function(parameters) {
    var version = parameters.meta.versions[0];
    var language = parameters.meta.languages[0];
    var out_base = '"out/'+path.basename(parameters.dir)+'"';
    var out_language = out_base + '/' + language;
    var out = out_base
        + '/' + version
        + '/' + language;
    var out_space = out_base.replace (' ', '\\');
    var main = has_main(parameters.dir, language);
    var cmd = 'mkdir -p ' + out
        + ' && ln -sf ' + out_base + ' ' + out_space
        + ' &&\nmake DIR="'+parameters.dir + '"'
        + ' VERSION="'+version+'"'
        + ' LANGUAGE='+language
        + ' OUT='+out
        + ' IN='+out_language
        + (parameters.meta.tss ? ' TSS='+ parameters.model : '')
        + (main ? ' MAIN="'+main +'"': '')
        + ' -f '+ __dirname + '/build.' + language + '.make';
    return util.spawn_sync_shell(cmd)
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
  execute: function(parameters) {
    var version = parameters.meta.versions[0];
    var language = parameters.meta.languages[0];
    var node_out = 'out/' + path.basename(parameters.dir);
    var out = '"' + node_out + '"/' + version + '/' + language;
    var interpreter = {
      goops:'guile',
      javascript:'node',
      python: 'python',
      cs: 'sh',
    }[language] || '';
    var env = process.env;
    if (language == 'javascript')
      env.NODE_PATH = node_out + '/javascript/dzn:' + env.NODE_PATH;
    var timeout = interpreter ? 10 : 5;
    var flush = parameters.meta.flush && ' --flush' || '';
    return run_traces(parameters, 'execute', function(trace) {
      var expectation = '"' + parameters.dir + '"/baseline/execute/' + language + path.basename (trace);
      var cmd = 'cat '+ trace + ' | ' + interpreter + ' ' + out + '/test' + flush;
      try {
        fs.lstatSync(expectation);
        return util.spawn_sync_shell(
          'timeout ' + timeout
            + ' diff -ywB'
            + ' ' + expectation
            + ' <(set -o pipefail;'
            + cmd
            + ' |& ' + __dirname + '/../bin/code2fdr'
            + ' || (' + cmd + ' ; echo "E""R""R""O""R"))',
          {env: env});
      } catch(e) {
        return util.spawn_sync_shell(
          'timeout ' + timeout
            + ' diff -ywB'
            + ' ' + '<(grep -E "^[^<.]+[.][^.>]+$" ' + trace + ')'
            + ' <(set -o pipefail;'
            + cmd
            + ' |& ' + __dirname + '/../bin/code2fdr'
            + ' || (' + cmd + ' ; echo "E""R""R""O""R"))');
      }
    })
      .fail (function(err) {console.log (err.stack); return {status: -1, output: err.stack}});
  }
  ,
  convert: function(parameters) {
    var model = parameters.meta.model || parameters.model;
    var node_dm = parameters.dir + '/' + model + '.dm';
    var dm = '"' + node_dm + '"';
    var imports = imports_string (parameters.meta.imports);
    return lstat(node_dm)
      .then (function(stats) {
        var out = '"out/'+path.basename(parameters.dir)+'"';
        var cmd = 'mkdir -p '+out+'; '
            + 'echo "'+dm+' -> '+out+'/'+model+'.dzn"; '
            + dzn()+' convert -g '+imports+' -o '+out+' '+dm+';'
            + 'sed -i -e "s,in void on(),in void on1()," '+out+'/*.dzn';
        return util.spawn_sync_shell(cmd)
          .then (function (result) {
            var parameters1 = util.deep_copy(parameters);
            parameters1.dir = out;
            parameters1.filename = out + '/' +model+'.dzn';
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
    var model = parameters.meta.model || parameters.model;
    var language_dir = parameters.dir + '/dzn';
    var lstat = q.denodeify(fs.lstat);
    var node_baseline = parameters.dir + '/baseline/parse/' + model + '.stderr';
    var baseline = '"' + node_baseline + '"';
    var imports = imports_string ([language_dir].concat(parameters.meta.imports || []));
    return lstat(node_baseline)
      .then (function(stats) {
        var expect = fs.readFileSync (node_baseline).toString ().trim ();
        expect = expect && expect != 'parse: no errors found' ? 1 : 0;
        return dzn() + ' parse '+imports+' "'+parameters.filename+'";'
          + ' r=$?;'
          + ' [ $r = ' + expect + ' ] || { echo exit: $r; exit 1; }';
        //return 'diff -uwB '+baseline+' <(' + dzn() + ' -p -v parse '+imports+' "'+parameters.filename+'" |& sed "s,.\r,,g")';
      })
      .fail (function(err) {
        return ' ' + dzn() + ' parse '+imports+' "'+parameters.filename+'"';
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
      var imports = imports_string (parameters.meta.imports);
      return util.spawn_sync_shell(
        'diff -uwB'
          + ' <(grep -v "<flush>" "'+ trace + '")'
          + ' <(grep -v "<flush>" "'+ trace + '"|'
          + ' ' + dzn(parameters.session) + ' run '+imports+' --strict --model=' + model + ' "' + parameters.filename + '" |&'
          + ' grep -E \'^trace:\' | sed -e \'s,trace:,,\' -e \'s/,/\\n/g\')')
        .fail (function(err) {console.log(err); return {status: -1, output: err}});
    });
  }
  ,
  traces: function(parameters) {
    var node_out = 'out/' + path.basename(parameters.dir);
    var out = '"' + node_out + '"';
    var flush = parameters.meta.flush ? ' --flush' : '';
    var illegal = parameters.meta.trace_illegals ? '-i ' : '';
    var model = parameters.meta.model || parameters.model;
    var queue = parameters.meta.queue ? '-q ' + parameters.meta.queue : '';
    var imports = imports_string (parameters.meta.imports);
    var cmd = dzn()
        + ' traces ' + imports + ' ' + queue + ' ' + illegal+flush+' -m '+model+' -o '+out+' "'+parameters.filename+'"';
    return lstat(out)
      .fail(function(){return util.spawn_sync_shell('mkdir -p ' + out);})
      .then(function(){return ls_traces(node_out);})
      .then(function(traces){if (!traces.length) traces = q(util.spawn_sync_shell(cmd)).then (function (){return ls_traces (node_out);}); return traces;})
      .then(function(traces){if (!traces.length) throw ('no traces'); return traces;})
      .fail(function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
  verify: function(parameters) {
    var model = parameters.meta.model || parameters.model;
    var language_dir = parameters.dir + '/dzn';
    var node_baseline = parameters.dir + '/baseline/verify/' + parameters.model;
    var baseline = '"' + node_baseline + '"';
    var dir = '"out/' + path.basename(parameters.dir) + '"/verify'
    var out = dir + '/"'+parameters.model + '"';
    var err = out + '.stderr';
    var queue = parameters.meta.queue ? '-q ' + parameters.meta.queue : '';
    var imports = imports_string ([language_dir].concat(parameters.meta.imports || []));
    var model_opt = parameters.meta.model === false ? '' : ' --model=' + model;
    return lstat (node_baseline)
      .then (function(stats) {
        return 'mkdir -p '+dir+';'
          + '{ set -o pipefail;'
          + dzn(parameters.session)
          + ' --verbose verify --all '
          + model_opt
          + ' '+imports
          + ' '+queue
          + ' "'+parameters.filename+'"'
          + ' 2>'+err
          + '| ' + __dirname + '/../bin/reorder > '+out
          + '| test ! -s '+baseline
          + '| test ! -s '+baseline+'.stderr'
          + ';}'
          + ' || (diff -uwB '+baseline+' '+out
          + '     && (test ! -s '+err
          + '         || (sed -i s,.\r,,g '+err+';'
          + '            diff -u '+baseline+'.stderr '+err+')))'
          + ' || { echo ' + err + ':; cat ' + err + '; false; }';
      })
      .fail (function(e) {
        return 'mkdir -p '+dir+';'
          + 'out="$(' + dzn(parameters.session) + ' verify --all '
          + model_opt
          + ' '+imports
          + ' '+queue
          + ' "'+parameters.filename+'"'
          + ' 2>' + err + ')";'
          + 'err="$(cat ' + err + ')";'
          + '[ "$out$err" = "" ] '
          + ' || { echo -e "verification output:\n$out"; '
          + '      echo ' + err + ':; cat ' + err + '; false; }';
      })
      .then (function(cmd) {
        return util.spawn_sync_shell(cmd);
      })
      .fail (function(err) {console.log(err); return {status: -1, output: err}});
  }
  ,
};

module.exports = aspects;
