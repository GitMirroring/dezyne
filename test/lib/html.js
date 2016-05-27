// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

var fs = require('fs');

function addLine(line) {
  return line + '\n';
}

var public = {
  write: function(result, filePath) {
    var lcStatus = (result.failed) ? 'fail' : 'pass';
    var ucStatus = (result.failed) ? '[FAIL]' : '[PASS]';
    var html = '';
    html +=  addLine('<!DOCTYPE html>');
    html +=  addLine('<html>');
    html +=  addLine('  <head>');
    html +=  addLine('    <title>' + result.title + '</title>');
    html +=  addLine('    <style>');
    html +=  addLine('      body {');
    html +=  addLine('        font-family: Sans-serif;');
    html +=  addLine('      }');
    html +=  addLine('      table {');
    html +=  addLine('          border-collapse: collapse;');
    html +=  addLine('      }');
    html +=  addLine('      table, th, td {');
    html +=  addLine('          border: 2px solid black;');
    html +=  addLine('      }');
    html +=  addLine('      td {');
    html +=  addLine('          text-align: center;');
    html +=  addLine('      }');
    html +=  addLine('      ol {');
    html +=  addLine('        font-size: 115%;');
    html +=  addLine('        font-weight: bold;');
    html +=  addLine('      }');
    html +=  addLine('      pre {');
    html +=  addLine('        display: inline;');
    html +=  addLine('      }');
    html +=  addLine('      h1.fail {');
    html +=  addLine('        color: red;');
    html +=  addLine('      }');
    html +=  addLine('      li.fail {');
    html +=  addLine('        color: red;');
    html +=  addLine('        cursor: pointer;');
    html +=  addLine('      }');
    html +=  addLine('      li.pass {');
    html +=  addLine('        cursor: pointer;');
    html +=  addLine('      }');
    html +=  addLine('      .output {');
    html +=  addLine('        font-size: initial;');
    html +=  addLine('        font-weight: initial;');
    html +=  addLine('        font-family: monospace;');
    html +=  addLine('        margin: 10px 0px;');
    html +=  addLine('      }');
    html +=  addLine('      .normal {');
    html +=  addLine('        font-weight: initial;');
    html +=  addLine('        color: initial;');
    html +=  addLine('      }');
    html +=  addLine('      .emphasize {');
    html +=  addLine('        font-weight: bold;');
    html +=  addLine('        color: red;');
    html +=  addLine('      }');
    html +=  addLine('    </style>');
    html +=  addLine('    <script>');
    html +=  addLine('      function toggle(element) {');
    html +=  addLine('        var details = document.getElementById(element.id + "_details");');
    html +=  addLine('        var expand = document.getElementById(element.id + "_expand");');
    html +=  addLine('        var collapse = document.getElementById(element.id + "_collapse");');
    html +=  addLine('        switch (details.style.display) {');
    html +=  addLine('        case "none":');
    html +=  addLine('          details.style.display = "block";');
    html +=  addLine('          expand.style.display = "none";');
    html +=  addLine('          collapse.style.display = "inline";');
    html +=  addLine('          break;');
    html +=  addLine('        case "block":');
    html +=  addLine('          details.style.display = "none";');
    html +=  addLine('          expand.style.display = "inline";');
    html +=  addLine('          collapse.style.display = "none";');
    html +=  addLine('          break;');
    html +=  addLine('        }');
    html +=  addLine('      }');
    html +=  addLine('    </script>');
    html +=  addLine('  </head>');
    html +=  addLine('  <body>');
    html +=  addLine('    <h1 id="target" class="' + lcStatus + '">Target: ' + result.target + ' ' + ucStatus + '</h1>');
    html +=  addLine('    <table>');
    html +=  addLine('      <tr>');
    html +=  addLine('        <th>Date</th>');
    html +=  addLine('        <th>Start time</th>');
    html +=  addLine('        <th>End time</th>');
    html +=  addLine('        <th>Elapsed time</th>');
    html +=  addLine('        <th>Total tests</th>');
    html +=  addLine('        <th>Passed</th>');
    html +=  addLine('        <th>Failed</th>');
    html +=  addLine('      </tr>');
    html +=  addLine('      <tr>');
    html +=  addLine('        <td>' + result.startTime.toLocaleDateString() + '</td>');
    html +=  addLine('        <td>' + result.startTime.toLocaleTimeString() + '</td>');
    html +=  addLine('        <td>' + result.endTime.toLocaleTimeString() + '</td>');
    html +=  addLine('        <td>' + result.elapsedTime + '</td>');
    html +=  addLine('        <td>' + (result.passed + result.failed) + '</td>');
    html +=  addLine('        <td>' + result.passed + '</td>');
    html +=  addLine('        <td>' + result.failed + '</td>');
    html +=  addLine('      </tr>');
    html +=  addLine('    </table>');
    html +=  addLine('    <ol>');
    html +=  result.items.map(function(item) {
      var lcStatus = (item.result.exitcode !== 0) ? 'fail' : 'pass';
      var ucStatus = (item.result.exitcode !== 0) ? '[FAIL]' : '[PASS]';
      var log = item.result.output.replace(/(error:)/ig, '</pre></span><span class="emphasize">$1</span><span class="normal"><pre>');
      var html = '';
      html += '      <li id="' + item.name + '" ';
      html += 'class=' + lcStatus;
      html +=  addLine(' onclick="toggle(this)">');
      html +=  addLine('        <img id="' + item.name + '_expand" style="vertical-align:center; display: inline;" src="lib/images/expand.gif">');
      html +=  addLine('        <img id="' + item.name + '_collapse" style="vertical-align:center; display: none;" src="lib/images/collapse.gif">');
      html +=  addLine('        ' + item.name + ' ' + item.result.status);
      html +=  addLine('      </li>');
      html +=  addLine('      <div class="output" id="' + item.name + '_details" style="display: none;"><span class="normal"><pre>' + log + '</pre></span></div>');
      return html;
    }).join('');
    html +=  addLine('    </ol>');
    html +=  addLine('  </body>');
    html +=  addLine('<html>');
    fs.writeFile(filePath, html, function(error) {
      if (error) {
        throw error;
      }
    });
  }
  ,
}

module.exports = public;
