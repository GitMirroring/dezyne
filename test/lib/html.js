// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
  transform: function(result) {
    var html = '';
    
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
    ln('          $target.css("background", "#CCFFCC");');
    ln('        });');
    ln('        jQuery("a.fail").click(function(event){');
    ln('          if ($target) $target.css("background", "white");');
    ln('          $target = jQuery(this.hash);');
    ln('          $target.css("background", "#FFCCCC");');
    ln('        });');
    ln('      });');
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
    ln('        background: #FFCCCC;');
    ln('      }');
    ln('      .pass {');
    ln('        color: black;');
    ln('        background: #CCFFCC;');
    ln('      }');
    ln('    </style>');
    ln('  </head>');
    ln('  <body>');
    var lcStatus = (result.failed) ? 'fail' : 'pass';
    var ucStatus = (result.failed) ? '[FAIL]' : '[PASS]';
    ln('    <h1 id="target" class="' + lcStatus + '">Target: ' + result.target + ' ' + ucStatus + '</h1>');
    ln('    <table>');
    ln('      <tr>');
    ln('        <th>Date</th>');
    ln('        <th>Start time</th>');
    ln('        <th>End time</th>');
    ln('        <th>Elapsed time</th>');
    ln('        <th>Total tests</th>');
    ln('        <th>Passed</th>');
    ln('        <th>Failed</th>');
    ln('      </tr>');
    ln('      <tr>');
    ln('        <td>' + result.startTime.toLocaleDateString() + '</td>');
    ln('        <td>' + result.startTime.toLocaleTimeString() + '</td>');
    ln('        <td>' + result.endTime.toLocaleTimeString() + '</td>');
    ln('        <td>' + result.elapsedTime + '</td>');
    ln('        <td>' + (result.passed + result.failed) + '</td>');
    ln('        <td>' + result.passed + '</td>');
    ln('        <td>' + result.failed + '</td>');
    ln('      </tr>');
    ln('    </table>');
    ln('    <p></p>');

    ln('    <table>');
    if (result.items.length) {
      ln('    <tr>');
      ln('      <th>ITEM</th>');

      var outcome = result.items[0].outcome.status;
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        var len = 1;
        if (typeof aspoutcome !== 'string') {
          len = Object.keys(aspoutcome).length;
        }
        ln('      <th colspan = "'+len+'">'+aspect+'</th>');
      });
      ln('    </tr>');
      ln('    <tr>');
      ln('      <th> </th>');

      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            ln('      <th>'+language+'</th>');
          });
        } else {
          ln('      <th> </th>');
        }
      });
      ln('    </tr>');
    }
    result.items.each(function(item) {
      var hname = item.name.replace(/\//g,'-');
      var outcome = item.outcome.status;
      ln('    <tr>');
      ln('      <td>'+item.name+'</td>');
      Object.keys(outcome).each(function(aspect) {
        var aspoutcome = outcome[aspect];
        if (typeof aspoutcome !== 'string') {
          Object.keys(aspoutcome).each(function(language) {
            var status = aspoutcome[language];
            var cl = (status=='FAILED'||status=='ERROR') ? 'fail' : 'pass';
            ln('      <td class="'+cl+'"><a href="#'+hname+'-'+aspect+'-'+language.replace(/\+/g,'p')+'" class="'+cl+'">'+status+'</a></td>');
          });
        } else {
          var status = aspoutcome;
          var cl = (status=='FAILED'||status=='ERROR') ? 'fail' : 'pass';
          ln('      <td class="'+cl+'"><a href="#'+hname+'-'+aspect+'" class="'+cl+'">'+status+'</a></td>');
        }
      });
      ln('    </tr>');
    });
    ln('    </table>');

    result.items.each(function(item) {
      var hname = item.name.replace(/\//g,'-');
      var outcome = item.outcome;
      if (typeof outcome.output != "string") {
        Object.keys(outcome.output).each(function(aspect_language) {
          var out = outcome.output[aspect_language];
          ln('        <div id="'+hname+'-'+aspect_language.replace(/\+/g,'p')+'">');
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
