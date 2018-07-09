// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2016, 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

var privates = {
  read: function() {
    var fileContent = '';
    var stdin = process.stdin;
    stdin.on('data', function(data) {
      fileContent += data;
    });
    stdin.on('end', function() {
      result = JSON.parse(fileContent);
      result.startTime = new Date(result.startTime);
      result.endTime = new Date(result.endTime);
      privates.write(result);
    });
  }
  ,
  overall_status: function(result) {
    if (result.status.failed) return 'fail';
    if (result.status.known) return 'known';
    if (result.status.solved) return 'solved';
    if (result.status.passed) return 'pass';
  }
  ,
  display_status: function(status) {
    if (status == 'fail') return '[FAIL]';
    if (status == 'known') return '[KNOWN]';
    if (status == 'solved') return '[SOLVED]';
    if (status == 'pass') return '[PASS]';
  }
  ,
  write: function(result) {
    var fileContent = privates.transform(result);
    console.log(fileContent);
  }
  ,
  all_languages(result) {
    if (result.items.length == 0) return [];
    var first = result.items[0].outcome;
    // pre: first is complete in its first language dependent aspect
    var order = first.order;
    var languages = [];
    var outcome = first.status;
    order.each(function(aspect) {
      var aspoutcome = outcome[aspect] || 'SKIPPED';
      if (typeof aspoutcome !== 'string' && languages.length==0) {
        Object.keys(aspoutcome).each(function(language) {
          languages.push(language);
        });
      }
    });
    return languages;
  }
  ,
  status2class: function(status) {
    if (status=='FAILED'||status=='ERROR'||status=='NOLOG') return 'fail';
    if (status=='KNOWN') return 'known';
    if (status=='SOLVED') return 'solved';
    return 'pass';
  }
  ,
  status_or: function(status1, status2) {
    if (status1 == 'fail' || status2 == 'fail') return 'fail';
    if (status1 == 'known' || status2 == 'known') return 'known';
    if (status1 == 'solved' || status2 == 'solved') return 'solved';
    if (status1 == 'pass' || status2 == 'pass') return 'pass';
    return null;
  }
  ,
  summary_per_aspect: function(testset) {
    var summary = {};

    var order = (testset.items.length) ? testset.items[0].outcome.order : [];
    var languages = privates.all_languages(testset);
    var outcome = (testset.items.length) ? testset.items[0].outcome.status : [];

    // pre: first item is complete is all its aspects
    order.each(function(aspect) {
      summary[aspect] = {};
      var aspoutcome = outcome[aspect] || 'SKIPPED';
      if (typeof aspoutcome !== 'string') {
        summary[aspect].languages = {};
        languages.each(function(language) {
          summary[aspect].languages[language] = 'pass';
        });
      } else {
        summary[aspect] = 'pass';
      }
    });

    testset.items.each(function(item) {
      var outcome = item.outcome.status;
      order.each(function(aspect) {
        var aspoutcome = outcome[aspect] || 'SKIPPED';
        if (typeof summary[aspect] !== 'string') {
          languages.each(function(language) {
            var status = privates.status2class(aspoutcome[language] || 'SKIPPED');
            summary[aspect].languages[language] = privates.status_or(status,summary[aspect].languages[language]);
          });
        } else {
          var status = privates.status2class(aspoutcome);
          summary[aspect] = privates.status_or(status,summary[aspect]);
        }
      });
    });

    Object.keys(summary).each(function(aspect) {
      if (summary[aspect].languages) {
        var status = 'pass';
        languages.each(function(language) {
          status = privates.status_or(status,summary[aspect].languages[language]);
        });
        summary[aspect].status = status;
      }
    });
    return summary;
  }
  ,
  transform: function(result) {
    var colors = { fail: 'rgba(255,200,200,.75)',
                   known: 'rgba(255,255,200,.75)',
                   solved: 'rgba(200,200,255,.75)',
                   pass: 'rgba(200,255,200,.75)',
                   white: 'rgba(255,255,255,.75)'
                 };

    var order = (result.items.length) ? result.items[0].outcome.order : [];
    var languages = privates.all_languages(result);

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

    ln('<!DOCTYPE html>');
    ln('<html>');
    ln('  <title>Result of '+result.target+'</title>');
    ln('  <head>');

//    ln('    <!-- development version, includes helpful console warnings -->');
//    ln('    <script src="https://cdn.jsdelivr.net/npm/vue@2.5.16/dist/vue.js"></script>');
    ln('    <!-- production version, optimized for size and speed -->');
    ln('    <script src="https://cdn.jsdelivr.net/npm/vue@2.5.16/dist/vue.min.js"></script>');

    ln('    <style>');
    ln('      body {');
    ln('        font-family: Sans-serif;');
    ln('      }');
    ln('      table {');
    ln('        border-collapse: collapse;');
    ln('      }');
    ln('      table, th, td {');
    ln('        border: 1px solid gray;');
    ln('      }');
    ln('      tr:nth-child(odd){');
    ln('        background-color: #CCCCCC');
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
    ln('      .fail {');
    ln('        background: '+colors["fail"]+';');
    ln('      }');
    ln('      .known {');
    ln('        background: '+colors["known"]+';');
    ln('      }');
    ln('      .solved {');
    ln('        background: '+colors["solved"]+';');
    ln('      }');
    ln('      .pass {');
    ln('        background: '+colors["pass"]+';');
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

    var lcStatus = privates.overall_status(result);
    var ucStatus = privates.display_status(lcStatus);

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
    ln('          <td class="pass">');
    ln('            <button id="button" class="pass" :style="{opacity:passOpa}" v-on:click="toggle(\'pass\')">');
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
    ln('          <td class="fail">');
    ln('            <button id="button" class="fail" :style="{opacity:failOpa}" v-on:click="toggle(\'fail\')">');
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
    ln('            <tr v-for="trow in testset.table.items" v-show="show(trow.status)" :class="trow.class">');
    ln('              <td v-for="aspect in trow.aspects" :class="aspect.class">');
    ln('                <template v-if="aspect.href">');
    ln('                  <a :href="aspect.href" v-show="show(aspect.status)" v-on:click="highlight(aspect.hclass,aspect.status)">{{aspect.content}}</a>');
    ln('                </template>');
    ln('                <template v-else>');
    ln('                  <span v-show="show(aspect.status)">{{aspect.content}}</span>');
    ln('                </template>');
    ln('              </td>');
    ln('            </tr>');
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

      var summary = privates.summary_per_aspect(testset);

      var header1 = [];

      header1.push({class: 'white', colspan: 1, name: 'ITEM'});
      header1.push({class: 'white', colspan: 1, name: 'META'});
      header1.push({class: 'white', colspan: 1, name: 'time'});

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

      order.each(function(aspect) {
        var cl = summary[aspect];
        if (cl.languages) {
          languages.each(function(language) {
            var cl = summary[aspect].languages[language];
            header2.push({status: cl, class: cl+' '+aspect+' '+p(language), name: language});
          })
        } else {
          header2.push({status: cl, class: cl+' '+aspect, name: ''});
        }
      });


      var items = [];

      testset.items.each(function(item) {
        var hname = m(item.name);
        var outcome = item.outcome.status;
        var aspects = [];

        var base = path.basename (item.name);
        var file;
        try {var f = item.name + '/' + base + '.dm'; file = fs.realpathSync (f);} catch (e) {}
        try {var f = item.name + '/' + base + '.dzn'; file = fs.realpathSync (f);} catch (e) {}
        var dir = path.basename (path.dirname (item.name));
        aspects.push({status: privates.status2class(item.status), class: privates.status2class(item.status), href: file, content: dir+'/'+ base});
        var meta;
        try {var f = item.name + '/' + 'META'; meta = fs.realpathSync (f);} catch (e) {}
        if (meta) {
          aspects.push({status: privates.status2class(item.status), class: 'white', href: meta, content: 'META'});
        } else {
          aspects.push({status: privates.status2class(item.status), class: 'white', href: '', name: ''});
        }
        aspects.push({status: privates.status2class(item.status), class: 'white', href: '', content: item.outcome.elapsed});
        order.each(function(aspect) {
          var aspoutcome = outcome[aspect] || 'SKIPPED';
          if (summary[aspect].languages) {
            languages.each(function(language) {
              var status = aspoutcome[language] || 'SKIPPED';
              var cl = privates.status2class(status);
              aspects.push({status: cl,
                            class: cl+' '+aspect+' '+p(language),
                            href: '#'+hname+'-'+aspect+'-'+p(language),
                            //hclass: cl+' '+aspect+' '+p(language),
                            hclass: m(item.name) + '-' + p(aspect) + '-' + p(language),
                            content: status});
            });
          } else {
            var status = aspoutcome;
            var cl = privates.status2class(status);
            aspects.push({status: cl,
                          class: cl+' '+aspect,
                          href: '#'+hname+'-'+aspect,
                          // hclass: cl+' '+aspect,
                          hclass: m(item.name) + '-' + p(aspect),
                          content: status});
          }
        });
        items.push({status: privates.status2class(item.status), class: privates.status2class(item.status), aspects: aspects});

      });

      var status = 'pass';
      items.each(function(item) {
        status = privates.status_or(status, item.status);
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


    data.toggles = {pass: false, solved: false, known: false, fail: true};
    data.colors = { pass: 'rgba(200,255,200,.75)',
                    solved: 'rgba(200,200,255,.75)',
                    known: 'rgba(255,255,200,.75)',
                    fail: 'rgba(255,200,200,.75)',
                    white: 'rgba(255,255,255,.75)'
                  };
    data.currentTarget = null;


    ln('  <script type="text/javascript">');
    ln('    var app = new Vue({');
    ln('      el: "#app",');
    ln('      data: ' + JSON.stringify(data, null, 2) + ',');
    ln('');
    ln('      computed: {');
    ln('          passOpa: function () {');
    ln('            return this.toggles[\'pass\'] ? 1 : 0.33');
    ln('          },');
    ln('          solvedOpa: function () {');
    ln('            return this.toggles[\'solved\'] ? 1 : 0.33');
    ln('          },');
    ln('          knownOpa: function () {');
    ln('            return this.toggles[\'known\'] ? 1 : 0.33');
    ln('          },');
    ln('          failOpa: function () {');
    ln('            return this.toggles[\'fail\'] ? 1 : 0.33');
    ln('          }');
    ln('      },');
    ln('      methods: {');
    ln('        show(st) {');
    ln('          return (!st) || this.toggles[st]');
    ln('        },');
    ln('        toggle(st) {');
    ln('          this.toggles[st] = !this.toggles[st];');
    ln('        },');
    ln('        showtable(index) {');
    ln('          return this.testsets[index].visible;');
    ln('        },');
    ln('        toggletable(index) {');
    ln('          this.testsets[index].visible = ! this.testsets[index].visible;');
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
}

var publics = {
  write: function(result, filePath) {
    var fileContent = privates.transform(result);
    fs.writeFileSync(filePath, fileContent);
  }
  ,
}

if (require.main === module) {
  // Called from the command line
  privates.read();
}

module.exports = publics;
