// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

var private = {
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
      private.write(result);
    });
  }
  ,
  write: function(result) {
    var fileContent = private.transform(result);
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
    html +=  private.addLine('<!DOCTYPE html>');
    html +=  private.addLine('<html>');
    html +=  private.addLine('  <head>');
    html +=  private.addLine('    <title>' + result.title + '</title>');
    html +=  private.addLine('    <style>');
    html +=  private.addLine('      body {');
    html +=  private.addLine('        font-family: Sans-serif;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      table {');
    html +=  private.addLine('          border-collapse: collapse;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      table, th, td {');
    html +=  private.addLine('          border: 2px solid black;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      td {');
    html +=  private.addLine('          text-align: center;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      ol {');
    html +=  private.addLine('        font-size: 115%;');
    html +=  private.addLine('        font-weight: bold;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      pre {');
    html +=  private.addLine('        display: inline;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      h1.fail {');
    html +=  private.addLine('        color: red;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      li.fail {');
    html +=  private.addLine('        color: red;');
    html +=  private.addLine('        cursor: pointer;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      li.pass {');
    html +=  private.addLine('        cursor: pointer;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      .output {');
    html +=  private.addLine('        font-size: initial;');
    html +=  private.addLine('        font-weight: initial;');
    html +=  private.addLine('        font-family: monospace;');
    html +=  private.addLine('        margin: 10px 0px;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      .normal {');
    html +=  private.addLine('        font-weight: initial;');
    html +=  private.addLine('        color: initial;');
    html +=  private.addLine('      }');
    html +=  private.addLine('      .emphasize {');
    html +=  private.addLine('        font-weight: bold;');
    html +=  private.addLine('        color: red;');
    html +=  private.addLine('      }');
    html +=  private.addLine('    </style>');
    html +=  private.addLine('    <script>');
    html +=  private.addLine('      function toggle(element) {');
    html +=  private.addLine('        var details = document.getElementById(element.id + "_details");');
    html +=  private.addLine('        var expand = document.getElementById(element.id + "_expand");');
    html +=  private.addLine('        var collapse = document.getElementById(element.id + "_collapse");');
    html +=  private.addLine('        switch (details.style.display) {');
    html +=  private.addLine('        case "none":');
    html +=  private.addLine('          details.style.display = "block";');
    html +=  private.addLine('          expand.style.display = "none";');
    html +=  private.addLine('          collapse.style.display = "inline";');
    html +=  private.addLine('          break;');
    html +=  private.addLine('        case "block":');
    html +=  private.addLine('          details.style.display = "none";');
    html +=  private.addLine('          expand.style.display = "inline";');
    html +=  private.addLine('          collapse.style.display = "none";');
    html +=  private.addLine('          break;');
    html +=  private.addLine('        }');
    html +=  private.addLine('      }');
    html +=  private.addLine('    </script>');
    html +=  private.addLine('  </head>');
    html +=  private.addLine('  <body>');
    html +=  private.addLine('    <h1 id="target" class="' + lcStatus + '">Target: ' + result.target + ' ' + ucStatus + '</h1>');
    html +=  private.addLine('    <table>');
    html +=  private.addLine('      <tr>');
    html +=  private.addLine('        <th>Date</th>');
    html +=  private.addLine('        <th>Start time</th>');
    html +=  private.addLine('        <th>End time</th>');
    html +=  private.addLine('        <th>Elapsed time</th>');
    html +=  private.addLine('        <th>Total tests</th>');
    html +=  private.addLine('        <th>Passed</th>');
    html +=  private.addLine('        <th>Failed</th>');
    html +=  private.addLine('      </tr>');
    html +=  private.addLine('      <tr>');
    html +=  private.addLine('        <td>' + result.startTime.toLocaleDateString() + '</td>');
    html +=  private.addLine('        <td>' + result.startTime.toLocaleTimeString() + '</td>');
    html +=  private.addLine('        <td>' + result.endTime.toLocaleTimeString() + '</td>');
    html +=  private.addLine('        <td>' + result.elapsedTime + '</td>');
    html +=  private.addLine('        <td>' + (result.passed + result.failed) + '</td>');
    html +=  private.addLine('        <td>' + result.passed + '</td>');
    html +=  private.addLine('        <td>' + result.failed + '</td>');
    html +=  private.addLine('      </tr>');
    html +=  private.addLine('    </table>');
    html +=  private.addLine('    <ol>');
    html +=  result.items.map(function(item) {
      var lcStatus = (item.result.exitcode !== 0) ? 'fail' : 'pass';
      var ucStatus = (item.result.exitcode !== 0) ? '[FAIL]' : '[PASS]';
      var log = item.result.output.replace(/(error:)/ig, '</pre></span><span class="emphasize">$1</span><span class="normal"><pre>');
      var html = '';
      html += '      <li id="' + item.name + '" ';
      html += 'class=' + lcStatus;
      html +=  private.addLine(' onclick="toggle(this)">');
      html +=  private.addLine('        <img id="' + item.name + '_expand" style="vertical-align:center; display: inline;" src="data:image/gif;base64,');
      html +=  private.addLine('          R0lGODlhEAAQAOZYAHyl4Zm454mp4Yqq4ZCv44en4JOz5IWl36PC65y76Imy5Y+u45S05Zu66F+J');
      html +=  private.addLine('          1VqF1Iur4p696Yav5Za15oWs45Kx5KC+6mKM1o2t45++6oio4aC/6qLA6oys4o+v46XE66G/6oam');
      html +=  private.addLine('          32GJ1XOb3Zi35p686ZGx5Hui4V2G1WaQ2GuU2ouq4WSO2GiS2aXD65Gv5G+Y3ISj34au5aTC63+n');
      html +=  private.addLine('          4YOj3nWd3l2G1KLA64Gq46bE7Jq56IOr44Cp442s45e25p286GaO2KLB65Sz5VmD0luF1H+m4ZW0');
      html +=  private.addLine('          5Z686GqS2Yur4Xii3p276IGi3oqy5Yan4GyW2liD0nef3pi25nCa3ISk34yz5v///////wAAAAAA');
      html +=  private.addLine('          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
      html +=  private.addLine('          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5');
      html +=  private.addLine('          BAEAAFgALAAAAAAQABAAAAeegFiCg4SFhoeGVopOChIyFDw9NACEVjofMwgcGxlICTtLhAouCDgg');
      html +=  private.addLine('          FhFMDQE/NoQSQhyoV1cBUxNDVIQUnEBWtAAMBiZQhDklCbTKVwQLSYRGq8u0GBBBhCckEwwAtFYd');
      html +=  private.addLine('          AwIXhFJHBhUEtCsCBSEOhCMVLws+SgIaTwcxN4QwHtUDNBQ4UKVGkweEVLRIweKCCAcoijwgEgWR');
      html +=  private.addLine('          xYuHAgEAOw==">');
      html +=  private.addLine('        <img id="' + item.name + '_collapse" style="vertical-align:center; display: none;" src="data:image/gif;base64,');
      html +=  private.addLine('          R0lGODlhDgAOAMQAAP///+vr6+Dg4P7+/uPj4/T09Pz8/Ojo6Pf395ycnN7e3t3d3fHx8e7u7n9/');
      html +=  private.addLine('          f1dXV8XFxba2tqOjo5+fn6enp8DAwMfHx9fX19PT07GxscrKyru7u+np6QAAAAAAAAAAACH5BAAA');
      html +=  private.addLine('          AAAALAAAAAAOAA4AAAVbIBAsZGkGAAesbLty1yDPtHxhRq7vOaYhwKAQqIEUjsjkEVJhOB3QqJNR');
      html +=  private.addLine('          2TSuj6z22thEAuCwGBzJHM7o9DlDIbjfcDdFIqjb73WJZaLo+/8TFgAQCYWGhxAAIQA7">');
      html +=  private.addLine('        ' + item.name + ' ' + item.result.status);
      html +=  private.addLine('      </li>');
      html +=  private.addLine('      <div class="output" id="' + item.name + '_details" style="display: none;"><span class="normal"><pre>' + log + '</pre></span></div>');
      return html;
    }).join('');
    html +=  private.addLine('    </ol>');
    html +=  private.addLine('  </body>');
    html +=  private.addLine('<html>');
    return html;
  }
  ,
}

var public = {
  write: function(result, filePath) {
    var fileContent = private.transform(result);
    fs.writeFileSync(filePath, fileContent);
  }
  ,
}

if (require.main === module) {
  // Called from the command line
  private.read();
}

module.exports = public;
