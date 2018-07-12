// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2016, 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Maarten van de Waarsenburg <maarten.van.de.waarsenburg@verum.com>
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

#! /usr/bin/env node

var fs = require('fs');
var path = require('path');

function read() {
  var fileContent = '';
  var stdin = process.stdin;
  stdin.on('data', function(data) {
    fileContent += data;
  });
  stdin.on('end', function() {
    result = JSON.parse(fileContent);
    result.startTime = new Date(result.startTime);
    result.endTime = new Date(result.endTime);
    write(result);
  });
}

function overall_status(result) {
  if (result.status.failed) return 'failed';
  if (result.status.known) return 'known';
  if (result.status.solved) return 'solved';
  if (result.status.passed) return 'passed';
}

function display_status(status) {
  if (status == 'failed') return '[FAIL]';
  if (status == 'known') return '[KNOWN]';
  if (status == 'solved') return '[SOLVED]';
  if (status == 'passed') return '[PASS]';
}

function write(result) {
  var fileContent = transform(result);
  console.log(fileContent);
}

function all_versions1(result) {
  if (result.items.length == 0) return [];
  var first = result.items[0].outcome;
  // pre: first is complete in its first language dependent aspect
  var f = first.order.find(function(aspect) {
    var a = first.status.outcome[aspect];
    return a && typeof a != string;
  });
  return Object.keys(first.status.outcome[f]);
}

function all_versions(item) {
  return Object.keys(item.outcome.status.code);
}

function all_languages(result) {
  var versions = all_versions(result.items[0]);
  return Object.keys(result.items[0].outcome.status.code[versions[0]]);
}

function status2class(status) {
  if (status=='FAILED'||status=='ERROR'||status=='NOLOG') return 'failed';
  if (status=='KNOWN') return 'known';
  if (status=='SOLVED') return 'solved';
  if (status=='SKIPPED') return 'skipped';
  if (status=='OK' || status=='PASSED') return 'passed';
  console.log('???????????????????? status=%j',status);
  return 'passed';
}

function status_or(status1, status2) {
  if (status1 == 'failed' || status2 == 'failed') return 'failed';
  if (status1 == 'known' || status2 == 'known') return 'known';
  if (status1 == 'solved' || status2 == 'solved') return 'solved';
  if (status1 == 'passed' || status2 == 'passed') return 'passed';
  return null;
}

function summary_per_aspect(testset) {
  var summary = {};

  var order = (testset.items.length) ? testset.items[0].outcome.order : [];
  var languages = all_languages(testset);
  var outcome = (testset.items.length) ? testset.items[0].outcome.status : [];

  // pre: first item is complete is all its aspects
  order.each(function(aspect) {
    summary[aspect] = {};
    var aspoutcome = outcome[aspect] || 'SKIPPED';
    if (typeof aspoutcome !== 'string') {
      summary[aspect].languages = {};
      languages.each(function(language) {
        summary[aspect].languages[language] = 'passed';
      });
    } else {
      summary[aspect] = 'passed';
    }
  });

  testset.items.each(function(item) {
    var outcome = item.outcome.status;
    all_versions(item).each(function(version) {
      order.each(function(aspect) {
        var aspoutcome = outcome[aspect] || 'SKIPPED';
        if (typeof summary[aspect] !== 'string') {
          languages.each(function(language) {
            var status = status2class(aspoutcome[version] && aspoutcome[version][language] || 'SKIPPED');
            summary[aspect].languages[language] = status_or(status,summary[aspect].languages[language]);
          });
        } else {
          var status = status2class(aspoutcome);
          summary[aspect] = status_or(status,summary[aspect]);
        }
      });
    });
  });

  Object.keys(summary).each(function(aspect) {
    if (summary[aspect].languages) {
      var status = 'passed';
      languages.each(function(language) {
        status = status_or(status,summary[aspect].languages[language]);
      });
      summary[aspect].status = status;
    }
  });
  return summary;
}

function transform(result) {
  var colors = { failed: 'rgb(255,200,200)',
                 known: 'rgb(255,255,200)',
                 solved: 'rgb(200,200,255)',
                 passed: 'rgb(200,255,200)',
                 skipped: 'rgb(235,255,235)',
                 white: 'rgb(255,255,255)'
               };

  var order = (result.items.length) ? result.items[0].outcome.order : [];
  var languages = all_languages(result);

  var html = '';

  function p(language) {
    return language.replace(/\+/g,'p');
  }

  function m(name) {
    return name.replace(/\//g,'-');
  }

  function ln(line) {
    html += line + '\n';
  }

  function rowspan(item, version) {
    var versions = all_versions(item);
    return versions.length - versions.indexOf(version);
  }

  ln('<!DOCTYPE html>');
  ln('<html>');
  ln('  <title>Result of '+result.target+'</title>');
  ln('  <head>');

  ln('    <!-- development version, includes helpful console warnings -->');
  ln('    <script src="https://cdn.jsdelivr.net/npm/vue@2.5.16/dist/vue.js"></script>');
  //    ln('    <!-- production version, optimized for size and speed -->');
  //    ln('    <script src="https://cdn.jsdelivr.net/npm/vue@2.5.16/dist/vue.min.js"></script>');

  ln('    <style>');
  ln('      body {');
  ln('        font-family: Sans-serif;');
  ln('      }');
  ln('      table {');
  ln('        border-collapse: collapse;');
  ln('      }');
  ln('      table, th, td {');
  ln('        border: thin solid gray;');
  ln('      }');
  ln('      td, th {');
  ln('        text-align: center;');
  ln('        font-size: 80%;');
  ln('        padding: 5px;');
  ln('      }');
  ln('      td.item, th.item {');
  ln('        text-align: left;');
  ln('      }');
  ln('      pre {');
  ln('        display: inline;');
  ln('      }');
  ln('      h2, h3, h4 {');
  ln('        padding: 4px;');
  ln('        margin: 4px 0px 4px 0px;');
  ln('        font-size: 110%;');
  ln('      }');
  ln('      h2:hover {');
  ln('        text-decoration: underline;');
  ln('        cursor: pointer;');
  ln('        color: blue;');
  ln('      }');
  ln('      a {');
  ln('        color: black;');
  ln('        text-decoration: none;');
  ln('      }');
  ln('      a:hover {');
  ln('        text-decoration: underline;');
  ln('        color: blue;');
  ln('      }');
  ln('      .failed {');
  ln('        background: '+colors["failed"]+';');
  ln('      }');
  ln('      .known {');
  ln('        background: '+colors["known"]+';');
  ln('      }');
  ln('      .solved {');
  ln('        background: '+colors["solved"]+';');
  ln('      }');
  ln('      .passed {');
  ln('        background: '+colors["passed"]+';');
  ln('      }');
  ln('      .skipped {');
  ln('        background: '+colors["skipped"]+';');
  ln('      }');
  ln('      .white {');
  ln('        background: '+colors["white"]+';');
  ln('      }');
  ln('      button {');
  ln('        background-color: rgba(255,255,255,0);');
  ln('        padding: 4px 32px;');
  ln('        text-align: center;');
  ln('        font-size: 100%;');
  ln('      }');
  ln('      [v-cloak] {');
  ln('        display: none;');
  ln('      }');
  ln('    </style>');
  ln('  </head>');
  ln('  <body>');
  ln('    <div id="app">');

  var lcStatus = overall_status(result);
  var ucStatus = display_status(lcStatus);

  ln('      <h1 id="target" class="' + lcStatus + '">Target: ' + result.target + ' ' + ucStatus + '</h1>');
  ln('      <table id="summary">');
  ln('        <tr>');
  ln('          <th class="white">Date</th>');
  ln('          <th class="white">Start time</th>');
  ln('          <th class="white">End time</th>');
  ln('          <th class="white">Elapsed time</th>');
  ln('          <th class="white">Total tests</th>');
  ln('          <th class="white">Passed</th>');
  ln('          <th class="white">Solved</th>');
  ln('          <th class="white">Known</th>');
  ln('          <th class="white">Failed</th>');
  ln('        </tr>');
  ln('        <tr>');
  ln('          <td class="white">' + result.startTime.toLocaleDateString() + '</td>');
  ln('          <td class="white">' + result.startTime.toLocaleTimeString() + '</td>');
  ln('          <td class="white">' + result.endTime.toLocaleTimeString() + '</td>');
  ln('          <td class="white">' + result.elapsedTime + '</td>');
  var total = result.status.passed + result.status.solved + result.status.known + result.status.failed;
  ln('          <td class="white">' + total + '</td>');
  ln('          <td class="passed">');
  ln('            <button id="button" class="passed" :style="{opacity:passedOpa}" v-on:click="toggle(\'passed\')">');
  ln('              ' + result.status.passed);
  ln('            </button>');
  ln('          </td>');
  ln('          <td class="solved">');
  ln('            <button id="button" class="solved" :style="{opacity:solvedOpa}" v-on:click="toggle(\'solved\')">');
  ln('              ' + result.status.solved);
  ln('            </button>');
  ln('          </td>');
  ln('          <td class="known">');
  ln('            <button id="button" class="known" :style="{opacity:knownOpa}" v-on:click="toggle(\'known\')">');
  ln('              ' + result.status.known);
  ln('            </button></td>');
  ln('          <td class="failed">');
  ln('            <button id="button" class="failed" :style="{opacity:failedOpa}" v-on:click="toggle(\'failed\')">');
  ln('              ' + result.status.failed);
  ln('            </button>');
  ln('          </td>');
  ln('        </tr>');
  ln('      </table>');
  ln('      <p></p>');

  ln('      <div v-cloak v-for="(testset,index) in testsets">');
  ln('        <h2 v-on:click="toggletable(index)" :class="testset.class">{{testset.name}}</h2>');
  ln('        <table id="details" v-show="showtable(index)">');
  ln('          <thead>');
  ln('            <tr>');
  ln('              <th v-for="thead in testset.table.header1" :class="thead.class" :colspan="thead.colspan">');
  ln('                <span v-show="show(thead.status)">{{thead.name}}</span>');
  ln('              </th>');
  ln('            </tr>');
  ln('            <tr>');
  ln('              <th v-for="thead in testset.table.header2" :class="thead.class">');
  ln('                <span v-show="show(thead.status)">{{thead.name}}</span>');
  ln('              </th>');
  ln('            </tr>');
  ln('          </thead>');
  ln('          <tbody>');
  ln('            <template v-for="item in testset.table.items">');
  ln('              <tr v-for="(version,vindex) in item.versions" v-show="show(version.status)" :class="version.class">');
  ln('                <template v-for="aspect in version.aspects">');
  ln('                  <template v-if="rowspan(item,vindex,aspect) > 0">');
  ln('                    <td :class="aspect.class" :rowspan="rowspan(item,vindex,aspect)" v-bind:style="{\'border-top\':style(item,vindex)}">');
  ln('                      <template v-if="aspect.href">');
  ln('                        <a :href="aspect.href" v-show="show(aspect.status)"v-on:click="highlight(aspect.hclass,aspect.status)">{{aspect.content}}</a>');
  ln('                      </template>');
  ln('                      <template v-else>');
  ln('                        <span v-show="show(aspect.status)">{{aspect.content}}</span>');
  ln('                      </template>');
  ln('                    </td>');
  ln('                  </template>');
  ln('                </template>');
  ln('              </tr>');
  ln('            </template>');
  ln('          </tbody>');
  ln('        </table>');
  ln('      </div>');

  ln('      <div v-cloak v-for="item in output" :id="item.id" :ref="item.id">');
  ln('        <hr>');
  ln('        <h3>{{item.header}}</h3>');
  ln('        <pre>{{item.out}}</pre>');
  ln('      </div>');

  ln('    </div>'); // id="app"

  var data = {};
  data.testsets = result.testsets.map(function(testset) {

    var summary = summary_per_aspect(testset);

    var header1 = [];

    header1.push({class: 'white', colspan: 1, name: 'ITEM'});
    header1.push({class: 'white', colspan: 1, name: 'META'});
    header1.push({class: 'white', colspan: 1, name: 'time'});
    header1.push({class: 'white', colspan: 1, name: 'version'});

    order.each(function(aspect) {
      var len = 1;
      var cl = summary[aspect];
      if (cl.languages) {
        len = Object.keys(summary[aspect].languages).length;
        cl = summary[aspect].status;
      }
      header1.push({status: cl, class: cl+' '+aspect, colspan: len, name: aspect});
    });

    var header2=  [];
    header2.push({class: 'white', name: ''});
    header2.push({class: 'white', name: ''});
    header2.push({class: 'white', name: ''});
    header2.push({class: 'white', name: ''});

    order.each(function(aspect) {
      var cl = summary[aspect];
      if (cl.languages) {
        languages.each(function(language) {
          var cl = summary[aspect].languages[language];
          header2.push({status: cl, class: cl+' '+aspect+' '+' '+p(language), name: language});
        })
      } else {
        header2.push({status: cl, class: cl+' '+aspect, name: ''});
      }
    });

    var items = [];

    testset.items.each(function(item) {
      var hname = m(item.name);
      var outcome = item.outcome.status;

      var nrversions = all_versions(item).length;
      var versions = [];

      all_versions(item).each(function(version) {
        var aspects = [];
        var base = path.basename (item.name);
        var file;
        try {var f = item.name + '/' + base + '.dm'; file = fs.realpathSync (f);} catch (e) {}
        try {var f = item.name + '/' + base + '.dzn'; file = fs.realpathSync (f);} catch (e) {}
        var dir = path.basename (path.dirname (item.name));
        aspects.push({status: status2class(item.status.versions[version]), class: status2class(item.status.overall), rowspan: rowspan(item,version), href: file, content: dir+'/'+ base});
        var meta;
        try {var f = item.name + '/' + 'META'; meta = fs.realpathSync (f);} catch (e) {}
        if (meta) {
          aspects.push({status: status2class(item.status.versions[version]), class: 'white', rowspan: rowspan(item,version), href: meta, content: 'META'});
        } else {
          aspects.push({status: status2class(item.status.versions[version]), class: 'white', rowspan: rowspan(item,version), href: '', name: ''});
        }
        aspects.push({status: status2class(item.status.versions[version]), class: 'white', rowspan: rowspan(item,version), href: '', content: item.outcome.elapsed});

        aspects.push({status: status2class(item.status.versions[version]), class: status2class(item.status.versions[version]), rowspan: -1, href: '', content: version});

        order.each(function(aspect) {
          var aspoutcome = outcome[aspect] || 'SKIPPED';
          if (summary[aspect].languages) {
            languages.each(function(language) {
              var status = aspoutcome[version] && aspoutcome[version][language] || 'SKIPPED';
              var cl = status2class(status);
              aspects.push({status: cl,
                            class: cl+' '+aspect+' '+p(language),
                            rowspan: -1,
                            href: '#'+hname+'-'+aspect+'-'+version+'-'+p(language),
                            //hclass: cl+' '+aspect+' '+p(language),
                            hclass: m(item.name) + '-' + p(aspect) + '-' + version + '-' + p(language),
                            content: status});
            });
          } else {
            var status = aspoutcome;
            var cl = status2class(status);
            aspects.push({status: cl,
                          class: cl+' '+aspect,
                          rowspan: rowspan(item,version),
                          href: '#'+hname+'-'+aspect,
                          // hclass: cl+' '+aspect,
                          hclass: m(item.name) + '-' + p(aspect),
                          content: status});
          }
        });
        versions.push({status: status2class(item.status.versions[version]), class: status2class(item.status.versions[version]), name: version, aspects: aspects});
      });

      items.push({status: status2class(item.status.overall), class: status2class(item.status.overall), versions: versions});



    });

    var status = 'passed';
    testset.items.each(function(item) {
      status = status_or(status, status2class(item.status.overall));
    });

    return {name: testset.name,
            visible: false,
            class: status,
            table: {
              header1: header1,
              header2: header2,
              items: items
            }};
  });
  data.output = [];
  result.items.each(function(item) {
    var hname = m(item.name);
    var outcome = item.outcome;
    if (typeof outcome.output !== 'string') {
      Object.keys(outcome.output).each(function(aspect_language) {
        var out = outcome.output[aspect_language];
        var output = {id: hname+'-'+p(aspect_language), header: item.name+'/'+aspect_language, out: out};
        data.output.push(output);
      });
    }
  });


  data.toggles = {passed: false, skipped: false, solved: false, known: false, failed: true};
  data.colors = { passed: 'rgb(200,255,200)',
                  skipped: 'rgb(235,255,235)',
                  solved: 'rgb(200,200,255)',
                  known: 'rgb(255,255,200)',
                  failed: 'rgb(255,200,200)',
                  white: 'rgb(255,255,255)'
                };
  data.currentTarget = null;


  ln('  <script type="text/javascript">');
  ln('    var app = new Vue({');
  ln('      el: "#app",');
  ln('      data: ' + JSON.stringify(data, null, 2) + ',');
  ln('');
  ln('      computed: {');
  ln('          passedOpa: function () {');
  ln('            return this.toggles[\'passed\'] ? 1 : 0.33');
  ln('          },');
  ln('          solvedOpa: function () {');
  ln('            return this.toggles[\'solved\'] ? 1 : 0.33');
  ln('          },');
  ln('          knownOpa: function () {');
  ln('            return this.toggles[\'known\'] ? 1 : 0.33');
  ln('          },');
  ln('          failedOpa: function () {');
  ln('            return this.toggles[\'failed\'] ? 1 : 0.33');
  ln('          }');
  ln('      },');
  ln('      methods: {');
  ln('        show(st) {');
  ln('          return (!st) || this.toggles[st]');
  ln('        },');
  ln('        toggle(st) {');
  ln('          this.toggles[st] = !this.toggles[st];');
  ln('          if (st=="passed") this.toggle("skipped");');
  ln('        },');
  ln('        showtable(index) {');
  ln('          return this.testsets[index].visible;');
  ln('        },');
  ln('        toggletable(index) {');
  ln('          this.testsets[index].visible = ! this.testsets[index].visible;');
  ln('        },');
  ln('        rowspan(item,vindex,aspect) {');
  ln('          if(aspect.rowspan == -1) return 1;');
  ln('          var hide = false;');
  ln('          for (i=0; i<vindex; i++) {');
  ln('            if (this.show(item.versions[i].status)) hide = true;');
  ln('          }');
  ln('          if (hide) return 0;');
  ln('          if (! this.show(item.versions[vindex].status)) return 0;');
  ln('          var vis = 0;');
  ln('          for (i=vindex; i<item.versions.length; i++) {');
  ln('            if (this.show(item.versions[i].status)) vis++;');
  ln('          }');
  ln('          return vis;');
  ln('        },');
  ln('        first_visible(item,vindex) {');
  ln('          for (i=0; i<vindex; i++) {');
  ln('            if (this.show(item.versions[i].status)) return false;');
  ln('          }');
  ln('          return this.show(item.versions[vindex].status);');
  ln('        },');
  ln('        style(item,vindex) {');
  ln('          return this.first_visible(item,vindex) ? "0.15em solid gray" : "0.1em solid lightGray";');
  ln('        },');
  ln('        highlight(hclass,status) {');
  ln('          var r = this.$refs[hclass];');
  ln('          if (r) {');
  ln('            if (this.currentTarget) this.currentTarget.style.background = this.colors["white"];');
  ln('            r[0].style.background = this.colors[status]');
  ln('            this.currentTarget=r[0];');
  ln('          }');
  ln('        }');
  ln('      }');
  ln('    });');
  ln(' </script>');
  ln('  </body>');
  ln('<html>');
  return html;
}

var publics = {
  write: function(result, filePath) {
    var fileContent = transform(result);
    fs.writeFileSync(filePath, fileContent);
  }
  ,
}

if (require.main === module) {
  // Called from the command line
  read();
}

module.exports = publics;
