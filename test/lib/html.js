// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Maarten van de Waarsenburg <maarten.van.de.waarsenburg@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
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
    html +=  privates.addLine('      h1.fail {');
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
    html +=  privates.addLine('      li.fail {');
    html +=  privates.addLine('        color: red;');
    html +=  privates.addLine('        cursor: pointer;');
    html +=  privates.addLine('      }');
    html +=  privates.addLine('      li.pass {');
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

      var outcome = result.items[0].outcome;
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        var len = 1;
        if (Object.keys(aspoutcome).indexOf('status') == -1) {
          len = Object.keys(aspoutcome).length;
        }
        html +=  privates.addLine('      <th colspan = "'+len+'">'+aspect+'</th>');
      });
      html +=  privates.addLine('    </tr>');
      html +=  privates.addLine('    <tr>');
      html +=  privates.addLine('      <th> </th>');
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        if (Object.keys(aspoutcome).indexOf('status') == -1) {
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
      var outcome = item.outcome;
      html +=  privates.addLine('    <tr>');
      html +=  privates.addLine('      <td><a href="#'+item.name+'">'+item.name+'</a></td>');
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        if (Object.keys(aspoutcome).indexOf('status') == -1) {
          Object.keys(aspoutcome).each(function(language) {
            var status = aspoutcome[language].status;
            html +=  privates.addLine('      <td><a href="#'+item.name+'/'+aspect+'/'+language+'">'+status+'</a></td>');
          });
        } else {
          var status = aspoutcome.status;
          html +=  privates.addLine('      <td><a href="#'+item.name+'/'+aspect+'">'+status+'</a></td>');
        }
      });
      html +=  privates.addLine('    </tr>');

    });
    html +=  privates.addLine('    </table>');

    result.items.each(function(item) {
      var outcome = item.outcome;
      html +=  privates.addLine('    <h2 id="'+item.name+'">'+item.name+'</h2>');
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        html +=  privates.addLine('      <h3 id="'+item.name+'/'+aspect+'">'+aspect+'</h3>');
        if (Object.keys(aspoutcome).indexOf('status') == -1) {
          Object.keys(aspoutcome).each(function(language) {
            var out = aspoutcome[language].output;
            html +=  privates.addLine('        <h4 id="'+item.name+'/'+aspect+'/'+language+'">'+language+'</h4>');
            html +=  privates.addLine('          <pre>'+out+'</pre>');
          });
        } else {
          var out = aspoutcome.output;
          html +=  privates.addLine('        <pre>'+out+'</pre>');
        }
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
