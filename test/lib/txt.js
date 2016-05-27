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
    var ucStatus = (result.failed) ? '[FAIL]' : '[PASS]';
    var text = '';
    text +=  private.addLine('Target: ' + result.target + ' ' + ucStatus);
    text +=  private.addLine('Date: ' + result.startTime.toLocaleDateString());
    text +=  private.addLine('Start time: ' + result.startTime.toLocaleTimeString());
    text +=  private.addLine('End time: ' + result.endTime.toLocaleTimeString());
    text +=  private.addLine('Elapsed time: ' + result.elapsedTime);
    text +=  private.addLine('Total tests: ' + (result.passed + result.failed));
    text +=  private.addLine('Passed: ' + result.passed);
    text +=  private.addLine('Failed: ' + result.failed);
    text +=  private.addLine('');
    text +=  result.items.map(function(item) {
      var ucStatus = (item.result.exitcode !== 0) ? '[FAIL]' : '[PASS]';
      var text = '';
      text +=  private.addLine('[....] ' + item.name);
      text +=  private.addLine(item.result.output);
      text +=  private.addLine(ucStatus + ' ' + item.name);
      text +=  private.addLine('');
     return text;
      text +=  private.addLine(item.result.output);
    }).join('');
    return text;
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
