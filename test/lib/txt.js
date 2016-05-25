// Dezyne --- Dezyne command line tools
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
    var status = (result.failed) ? 'failed' : 'succeeded';
    var text = '';
    text +=  addLine('Target: ' + result.target + ' (' + status + ')');
    text +=  addLine('Date: ' + result.startTime.toLocaleDateString());
    text +=  addLine('Start time: ' + result.startTime.toLocaleTimeString());
    text +=  addLine('End time: ' + result.endTime.toLocaleTimeString());
    text +=  addLine('Elapsed time: ' + result.elapsedTime);
    text +=  addLine('Total tests: ' + (result.succeeded + result.failed));
    text +=  addLine('Succeeded: ' + result.succeeded);
    text +=  addLine('Failed: ' + result.failed);
    text +=  addLine('');
    text +=  result.items.map(function(item) {
      var text = '';
      text +=  addLine(item.name + ' ' + item.result.status);
      text +=  addLine(item.result.output);
      text +=  addLine('Finished test: ' + item.name + '; status: ' + status);
      text +=  addLine('');
     return text;
      text +=  addLine(item.result.output);
    }).join('');
    fs.writeFile(filePath, text, function(error) {
      if (error) {
        throw error;
      }
    });
  }
  ,
}

module.exports = public;
