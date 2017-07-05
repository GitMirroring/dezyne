// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2016, 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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
  summary_per_aspect: function(result) {
    var summary = {};
    var order = (result.items.length) ? result.items[0].outcome.order : [];

    function status_or(status1, status2) {
      if (status1 == 'fail' || status2 == 'fail') return 'fail';
      if (status1 == 'known' || status2 == 'known') return 'known';
      if (status1 == 'solved' || status2 == 'solved') return 'solved';
      if (status1 == 'pass' || status2 == 'pass') return 'pass';
      return null;
    }

    var outcome = (result.items.length) ? result.items[0].outcome.status : [];
    order.each(function(aspect) {
      summary[aspect] = {};
      var aspoutcome = outcome[aspect] || 'NOLOG';
      if (typeof aspoutcome !== 'string') {
        summary[aspect].lan = {};
        Object.keys(aspoutcome).each(function(language) {
          summary[aspect].lan[language] = 'pass';
        });
      } else {
        summary[aspect] = 'pass';
      }
    });

    result.items.each(function(item) {
      function status2class(status) {
        if (status=='FAILED'||status=='ERROR'||status=='NOLOG') return 'fail';
        if (status=='KNOWN') return 'known';
        if (status=='SOLVED') return 'solved';
        return 'pass';
      }
      var outcome = item.outcome.status;
      order.each(function(aspect) {
        var aspoutcome = outcome[aspect] || 'NOLOG';
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            var status = status2class(aspoutcome[language]);
            summary[aspect].lan[language] = status_or(status,summary[aspect].lan[language]);
          });
        } else {
          var status = status2class(aspoutcome);
          summary[aspect] = status_or(status,summary[aspect]);
        }
      });
    });

    Object.keys(summary).each(function(aspect) {
      if (summary[aspect].lan) {
        var status = 'pass';
        Object.keys(summary[aspect].lan).each(function(language) {
          status = status_or(status,summary[aspect].lan[language]);
        });
        summary[aspect].status = status;
      }
    });
    return summary;
  }
  ,
  transform: function(result) {
    var cfail   = 'rgba(255,200,200,.75)';
    var cknown  = 'rgba(255,255,200,.75)';
    var csolved = 'rgba(200,200,255,.75)';
    var cpass   = 'rgba(200,255,200,.75)';
    var cwhite  = 'rgba(255,255,255,.75)';

    var summary = privates.summary_per_aspect(result);

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
    ln('    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.2/jquery.min.js"></script>');
    ln('    <script type="text/javascript">');
    ln('      var $target;');
    ln('      jQuery(document).ready(function() {');
    ln('        jQuery("a.pass").click(function(event){');
    ln('          if ($target) $target.css("background", "white");');
    ln('          $target = jQuery(this.hash);');
    ln('          $target.css("background", "'+cpass+'");');
    ln('        });');
    ln('        jQuery("a.fail").click(function(event){');
    ln('          if ($target) $target.css("background", "white");');
    ln('          $target = jQuery(this.hash);');
    ln('          $target.css("background", "'+cfail+'");');
    ln('        });');
    ln('        jQuery("a.known").click(function(event){');
    ln('          if ($target) $target.css("background", "white");');
    ln('          $target = jQuery(this.hash);');
    ln('          $target.css("background", "'+cknown+'");');
    ln('        });');
    ln('        jQuery("a.solved").click(function(event){');
    ln('          if ($target) $target.css("background", "white");');
    ln('          $target = jQuery(this.hash);');
    ln('          $target.css("background", "'+csolved+'");');
    ln('        });');
    ln('      });');
    ln('      var show = {"pass": true, "solved": true, "known": true, "fail": true };');
    ln('       function hide(result) {');
    ln('        show[result] = ! show[result];');
    ln('        var showme = show[result];');
    ln('        var bt = document.querySelector("button."+result);');
    ln('        bt.style.opacity=showme ? 1 : .33;');
    ln('        hideRows(showme,result);');
    ln('        hideColumns(showme,result);');
    ln('      }');
    ln('      function hideRows(showme,result) {');
    ln('        var text = showme ? "" : "display:none;";');
    ln('        var items = document.querySelectorAll("tr."+result);');
    ln('        for (var i = 0; i < items.length; ++i) {');
    ln('          items[i].style.cssText = text;');
    ln('        }');
    ln('      }');
    ln('      function hideColumns(showme,result) {');
    ln('        var table = document.getElementById("details");');
    ln('        var row = table.rows[1];');
    ln('        for (var j = 0, col; col = row.cells[j]; j++) {');
    ln('          var cl = col.getAttribute("class").split(" ");');
    ln('          if (cl[0] === result) {');
    ln('            hideColumn(showme,cl[1],cl.length>2 ? cl[2] : null);');
    ln('          }');
    ln('        }');
    ln('      }');
    ln('      function hideColumn(showme,aspect,language) {');
    ln('        var text = showme ? "" : "font-size:0%;";');
    ln('        var query = "."+aspect+(language ? ("."+language) : "");');
    ln('        var items = document.querySelectorAll("th"+query);');
    ln('        for (var i = 0; i < items.length; ++i) {');
    ln('          items[i].style.cssText = text;');
    ln('        }');
    ln('        items = document.querySelectorAll("td"+query);');
    ln('        for (var i = 0; i < items.length; ++i) {');
    ln('          items[i].style.cssText = text;');
    ln('        }');
    ln('      }');
    ln('      function initTables() {');
    ln('        hide(\'pass\');');
    ln('        hide(\'solved\');');
    ln('        hide(\'known\');');
    ln('      }');
    ln('    </script>');
    ln('    <title>' + result.title + '</title>');
    ln('    <style>');
    ln('      body {');
    ln('        font-family: Sans-serif;');
    ln('      }');
    ln('      table {');
    ln('          border-collapse: collapse;');
    ln('      }');
    ln('      table, th, td {');
    ln('          border: 1px solid gray;');
    ln('      }');
    ln('      tr:nth-child(odd){');
    ln('          background-color: #CCCCCC');
    ln('      }');
    ln('      td, th {');
    ln('          text-align: center;');
    ln('          font-size: 80%;');
    ln('          padding: 5px;');
    ln('      }');
    ln('      pre {');
    ln('        display: inline;');
    ln('      }');
    ln('      h2, h3, h4 {');
    ln('        line-height: 0.3;');
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
    ln('        background: '+cfail+';');
    ln('      }');
    ln('      .known {');
    ln('        background: '+cknown+';');
    ln('      }');
    ln('      .solved {');
    ln('        background: '+csolved+';');
    ln('      }');
    ln('      .pass {');
    ln('        color: black;');
    ln('        background: '+cpass+';');
    ln('      }');
    ln('      .white {');
    ln('        background: '+cwhite+';');
    ln('      }');
    ln('      button {');
    ln('        background-color: rgba(255,255,255,0);');
    ln('        padding: 4px 32px;');
    ln('        text-align: center;');
    ln('        font-size: 100%;');
    ln('      }');
    ln('    </style>');
    ln('  </head>');
    ln('  <body onload="initTables();">');
    var lcStatus = privates.overall_status(result);
    var ucStatus = privates.display_status(lcStatus);
    ln('    <h1 id="target" class="' + lcStatus + '">Target: ' + result.target + ' ' + ucStatus + '</h1>');
    ln('    <table id="summary">');
    ln('      <tr>');
    ln('        <th class="white">Date</th>');
    ln('        <th class="white">Start time</th>');
    ln('        <th class="white">End time</th>');
    ln('        <th class="white">Elapsed time</th>');
    ln('        <th class="white">Total tests</th>');
    ln('        <th class="white">Passed</th>');
    ln('        <th class="white">Solved</th>');
    ln('        <th class="white">Known</th>');
    ln('        <th class="white">Failed</th>');
    ln('      </tr>');
    ln('      <tr>');
    ln('        <td class="white">' + result.startTime.toLocaleDateString() + '</td>');
    ln('        <td class="white">' + result.startTime.toLocaleTimeString() + '</td>');
    ln('        <td class="white">' + result.endTime.toLocaleTimeString() + '</td>');
    ln('        <td class="white">' + result.elapsedTime + '</td>');
    ln('        <td class="white">' + (result.status.passed + result.status.solved
       + result.status.known + result.status.failed) + '</td>');
    ln('        <td class="pass"><button id="button" class="pass" onclick="hide(\'pass\')">'
       + result.status.passed + '</button></td>');
    ln('        <td class="solved"><button id="button" class="solved" onclick="hide(\'solved\')">'
       + result.status.solved + '</button></td>');
    ln('        <td class="known"><button id="button" class="known" onclick="hide(\'known\')">'
       + result.status.known + '</button></td>');
    ln('        <td class="fail"><button id="button" class="fail" onclick="hide(\'fail\')">'
       + result.status.failed + '</button></td>');
    ln('      </tr>');
    ln('    </table>');
    ln('    <p></p>');

    var order = (result.items.length) ? result.items[0].outcome.order : [];

    ln('    <table id="details">');
    if (result.items.length) {
      ln('    <tr>');
      ln('      <th class="white">ITEM</th>');
      ln('      <th class="white">time</th>');

      var outcome = (result.items.length) ? result.items[0].outcome.status : [];
      order.each(function(aspect) {
        var aspoutcome = outcome[aspect] || 'NOLOG';
        var len = 1;
        if (typeof aspoutcome !== 'string') {
          len = Object.keys(aspoutcome).length;
          var cl = summary[aspect].status;
          ln('      <th class="'+cl+' '+aspect+'" colspan="'+len+'">'+aspect+'</th>');
        } else {
          var cl = summary[aspect];
          ln('      <th class="'+cl+' '+aspect+'">'+aspect+'</th>');
        }
      });
      ln('    </tr>');
      ln('    <tr>');
      ln('      <th class="white"> </th>');
      ln('      <th class="white"> </th>');

      order.each(function(aspect) {
        var aspoutcome = outcome[aspect] || 'NOLOG';
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            var cl = summary[aspect].lan[language];
              ln('      <th class="'+cl+' '+aspect+' '+p(language)+'">'+language+'</th>');
          });
        } else {
          var cl = summary[aspect];
          ln('      <th class="'+cl+' '+aspect+'"> </th>');
        }
      });
      ln('    </tr>');
    }
    result.items.each(function(item) {
      function status2class(status) {
        if (status=='FAILED'||status=='ERROR'||status=='NOLOG') return 'fail';
        if (status=='KNOWN') return 'known';
        if (status=='SOLVED') return 'solved';
        return 'pass';
      }
      var hname = m(item.name);
      var outcome = item.outcome.status;
      ln('    <tr class="'+status2class(item.status)+'">');
      var base = path.basename (item.name);
      var file = item.name;
      try {var f = file + '/' + base + '.dm'; file = fs.realpathSync (f);} catch (e) {}
      try {var f = file + '/' + base + '.dzn'; file = fs.realpathSync (f);} catch (e) {}
      var dir = path.basename (path.dirname (item.name));
      ln('      <td class="'+status2class(item.status)+'"><a href="' + file +'">'+dir+'/'+ base+'</a></td>');
      ln('      <td class="white">'+item.outcome.elapsed+'</a></td>');
      order.each(function(aspect) {
        var aspoutcome = outcome[aspect] || 'NOLOG';
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            var status = aspoutcome[language];
            var cl = status2class(status);
            ln('      <td class="'+cl+' '+aspect+' '+p(language)+'">'
               +'<a href="#'+hname+'-'+aspect+'-'+p(language)+'" class="'+cl+' '+aspect+' '+p(language)+'">'
               +status+'</a></td>');
          });
        } else {
          var status = aspoutcome;
          var cl = status2class(status);
          ln('      <td class="'+cl+' '+aspect+'">'
             +'<a href="#'+hname+'-'+aspect+'" class="'+cl+' '+aspect+'">'+status+'</a></td>');
        }
      });
      ln('    </tr>');
    });
    ln('    </table>');

    result.items.each(function(item) {
      var hname = m(item.name);
      var outcome = item.outcome;
      if (typeof outcome.output != "string") {
        Object.keys(outcome.output).each(function(aspect_language) {
          var out = outcome.output[aspect_language];
            ln('        <div id="'+hname+'-'+p(aspect_language)+'">');
          ln('          <hr>');
          ln('          <h3>'+item.name+'/'+aspect_language+'</h3>');
          ln('          <pre>'+out+'</pre>');
          ln('        </div>');
        });
      }
    });
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
