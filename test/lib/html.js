// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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
  write: function(result) {
    var fileContent = privates.transform(result);
    console.log(fileContent);
  }
  ,
  addLine: function(line) {
    return line + '\n';
  }
  ,
  transform: function(result) {
    var lcStatus = (result.failed) ? 'fail' : 'pass';
    var ucStatus = (result.failed) ? '[FAIL]' : '[PASS]';
    var html = '';
    html +=  privates.addLine('<!DOCTYPE html>');
    html +=  privates.addLine('<html>');
    html +=  privates.addLine('  <head>');
    html +=  privates.addLine('    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.2/jquery.min.js"></script>');
    html +=  privates.addLine('    <script type="text/javascript">');
    html +=  privates.addLine('      var $target;');
    html +=  privates.addLine('      jQuery(document).ready(function() {');
    html +=  privates.addLine('        jQuery("a.pass").click(function(event){');
    html +=  privates.addLine('          if ($target) $target.css("background", "white");');
    html +=  privates.addLine('          $target = jQuery(this.hash);');
    html +=  privates.addLine('          $target.css("background", "#CCFFCC");');
    html +=  privates.addLine('        });');
    html +=  privates.addLine('        jQuery("a.fail").click(function(event){');
    html +=  privates.addLine('          if ($target) $target.css("background", "white");');
    html +=  privates.addLine('          $target = jQuery(this.hash);');
    html +=  privates.addLine('          $target.css("background", "#FFCCCC");');
    html +=  privates.addLine('        });');
    html +=  privates.addLine('      });');
    html +=  privates.addLine('    </script>');
    html +=  privates.addLine('    <title>' + result.title + '</title>');
    html +=  privates.addLine('    <style>');
    html +=  privates.addLine('      body {');
    html +=  privates.addLine('        font-family: Sans-serif;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      table {');
    html +=  privates.addLine('          border-collapse: collapse;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      table, th, td {');
    html +=  privates.addLine('          border: 1px solid gray;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      td {');
    html +=  privates.addLine('          text-align: center;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      td, th {');
    html +=  privates.addLine('          padding: 5px;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      pre {');
    html +=  privates.addLine('        display: inline;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      h1.fail, h2.fail, h3.fail, h4.fail {');
    html +=  privates.addLine('        color: red;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      h2, h3, h4 {');
    html +=  privates.addLine('        line-height: 0.3;');
    html +=  privates.addLine('        color: blue;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      a {');
    html +=  privates.addLine('        color: black;');
    html +=  privates.addLine('        text-decoration: none;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      a:hover {');
    html +=  privates.addLine('        text-decoration: underline;');
    html +=  privates.addLine('        color: blue;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      .fail {');
    html +=  privates.addLine('        background: #FFCCCC;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      .pass {');
    html +=  privates.addLine('        color: black;');
    html +=  privates.addLine('        background: #CCFFCC;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      li.fail {');
    html +=  privates.addLine('        color: red;');
    html +=  privates.addLine('        cursor: pointer;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      .output {');
    html +=  privates.addLine('        font-size: initial;');
    html +=  privates.addLine('        font-weight: initial;');
    html +=  privates.addLine('        font-family: monospace;');
    html +=  privates.addLine('        margin: 10px 0px;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      .normal {');
    html +=  privates.addLine('        font-weight: initial;');
    html +=  privates.addLine('        color: initial;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      .emphasize {');
    html +=  privates.addLine('        font-weight: bold;');
    html +=  privates.addLine('        color: red;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('    </style>');
    html +=  privates.addLine('  </head>');
    html +=  privates.addLine('  <body>');
    html +=  privates.addLine('    <h1 id="target" class="' + lcStatus + '">Target: ' + result.target + ' ' + ucStatus + '</h1>');
    html +=  privates.addLine('    <table>');
    html +=  privates.addLine('      <tr>');
    html +=  privates.addLine('        <th>Date</th>');
    html +=  privates.addLine('        <th>Start time</th>');
    html +=  privates.addLine('        <th>End time</th>');
    html +=  privates.addLine('        <th>Elapsed time</th>');
    html +=  privates.addLine('        <th>Total tests</th>');
    html +=  privates.addLine('        <th>Passed</th>');
    html +=  privates.addLine('        <th>Failed</th>');
    html +=  privates.addLine('      </tr>');
    html +=  privates.addLine('      <tr>');
    html +=  privates.addLine('        <td>' + result.startTime.toLocaleDateString() + '</td>');
    html +=  privates.addLine('        <td>' + result.startTime.toLocaleTimeString() + '</td>');
    html +=  privates.addLine('        <td>' + result.endTime.toLocaleTimeString() + '</td>');
    html +=  privates.addLine('        <td>' + result.elapsedTime + '</td>');
    html +=  privates.addLine('        <td>' + (result.passed + result.failed) + '</td>');
    html +=  privates.addLine('        <td>' + result.passed + '</td>');
    html +=  privates.addLine('        <td>' + result.failed + '</td>');
    html +=  privates.addLine('      </tr>');
    html +=  privates.addLine('    </table>');
    html +=  privates.addLine('    <p></p>');

    html +=  privates.addLine('    <table>');
    if (result.items.length) {
      html +=  privates.addLine('    <tr>');
      html +=  privates.addLine('      <th>ITEM</th>');

      var outcome = result.items[0].outcome.status;
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        var len = 1;
        if (typeof aspoutcome !== 'string') {
          len = Object.keys(aspoutcome).length;
        }
        html +=  privates.addLine('      <th colspan = "'+len+'">'+aspect+'</th>');
      });
      html +=  privates.addLine('    </tr>');
      html +=  privates.addLine('    <tr>');
      html +=  privates.addLine('      <th> </th>');

      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            html +=  privates.addLine('      <th>'+language+'</th>');
          });
        } else {
          html +=  privates.addLine('      <th> </th>');
        }
      });
      html +=  privates.addLine('    </tr>');
    }
    result.items.each(function(item) {
      var hname = item.name.replace(/\//g,'-');
      var outcome = item.outcome.status;
      html +=  privates.addLine('    <tr>');
      html +=  privates.addLine('      <td>'+item.name+'</td>');
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            var status = aspoutcome[language];
            var cl = (status=='FAILED'||status=='ERROR') ? 'fail' : 'pass';
            html +=  privates.addLine('      <td class="'+cl+'"><a href="#'+hname+'-'+aspect+'-'+language+'" class="'+cl+'">'+status+'</a></td>');
          });
        } else {
          var status = aspoutcome;
          var cl = (status=='FAILED'||status=='ERROR') ? 'fail' : 'pass';
          html +=  privates.addLine('      <td class="'+cl+'"><a href="#'+hname+'-'+aspect+'" class="'+cl+'">'+status+'</a></td>');
        }
      });
      html +=  privates.addLine('    </tr>');
    });
    html +=  privates.addLine('    </table>');

    result.items.each(function(item) {
      var hname = item.name.replace(/\//g,'-');
      var outcome = item.outcome;
      Object.keys(outcome.output).each(function(aspect_language) {
        var out = outcome.output[aspect_language];
        html +=  privates.addLine('        <div id="'+hname+'-'+aspect_language+'">');
        html +=  privates.addLine('          <hr>');
        html +=  privates.addLine('          <h3>'+item.name+'/'+aspect_language+'</h3>');
        html +=  privates.addLine('          <pre>'+out+'</pre>');
        html +=  privates.addLine('        </div>');
      });
    });
    html +=  privates.addLine('  </body>');
    html +=  privates.addLine('<html>');
    return html;
  }
  ,
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
