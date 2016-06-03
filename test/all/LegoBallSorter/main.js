// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

var dezyne = typeof (dezyne) !== undefined && dezyne ? dezyne : require (__dirname + '/dezyne/runtime');
dzn.extend (dezyne, require (__dirname + '/dezyne/LegoBallSorter'));

config = {
  get: function(x) { return 0; }
};

var relaxed = true;
var lines = [];
function read_line() {
  if (lines.length) {
    return lines.pop();
  }
  return '';
}

function drop_prefix(string, prefix) {
  if (string.indexOf(prefix) === 0) {
    return string.slice(prefix.length);
  }
  return string;
}

function consume_synchronous_out_events(event_map) {
  read_line();
  var event;
  while (event = read_line()) {
    if (!event_map[event]) {
      break;
    }
    event_map[event]();
  }
  return event;
}

function log_in(prefix, event, event_map) {
  console.error(prefix + event);
  if (relaxed) return;
  consume_synchronous_out_events(event_map);
  console.error(prefix + 'return');
}

function log_out(prefix, event) {
  console.error(prefix + event);
}

function log_valued(prefix, event, event_map, string_to_value, value_to_string) {
  console.error(prefix + event);
  if (relaxed) return 0;
  var s = consume_synchronous_out_events(event_map);
  var r = string_to_value(s);
  if (r !== undefined) {
    console.error(prefix + value_to_string[r]);
    return r;
  }
  throw 'runtime error: "' + s + '" is not a reply value'
}

function LegoBallSorter_fill_event_map(m)
{
  var e = {
    'ctrl.calibrate': m.ctrl.in.calibrate,
    'ctrl.stop': m.ctrl.in.stop,
    'ctrl.operate': m.ctrl.in.operate,
  };
  m.ctrl.out.calibrated = function() {log_out('ctrl.', 'calibrated', e);};
  m.ctrl.out.finished = function() {log_out('ctrl.', 'finished', e);};
  m.brick1_aA.in.move = function() {log_in('brick1_aA.', 'move', e);};
  m.brick1_aA.in.run = function() {log_in('brick1_aA.', 'run', e);};
  m.brick1_aA.in.stop = function() {log_in('brick1_aA.', 'stop', e);};
  m.brick1_aA.in.coast = function() {log_in('brick1_aA.', 'coast', e);};
  m.brick1_aA.in.zero = function() {log_in('brick1_aA.', 'zero', e);};
  m.brick1_aA.in.position = function() {log_in('brick1_aA.', 'position', e);};
  m.brick1_aA.in.at = function() {return log_valued('brick1_aA.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick1_aA.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick1_aB.in.move = function() {log_in('brick1_aB.', 'move', e);};
  m.brick1_aB.in.run = function() {log_in('brick1_aB.', 'run', e);};
  m.brick1_aB.in.stop = function() {log_in('brick1_aB.', 'stop', e);};
  m.brick1_aB.in.coast = function() {log_in('brick1_aB.', 'coast', e);};
  m.brick1_aB.in.zero = function() {log_in('brick1_aB.', 'zero', e);};
  m.brick1_aB.in.position = function() {log_in('brick1_aB.', 'position', e);};
  m.brick1_aB.in.at = function() {return log_valued('brick1_aB.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick1_aB.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick1_aC.in.move = function() {log_in('brick1_aC.', 'move', e);};
  m.brick1_aC.in.run = function() {log_in('brick1_aC.', 'run', e);};
  m.brick1_aC.in.stop = function() {log_in('brick1_aC.', 'stop', e);};
  m.brick1_aC.in.coast = function() {log_in('brick1_aC.', 'coast', e);};
  m.brick1_aC.in.zero = function() {log_in('brick1_aC.', 'zero', e);};
  m.brick1_aC.in.position = function() {log_in('brick1_aC.', 'position', e);};
  m.brick1_aC.in.at = function() {return log_valued('brick1_aC.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick1_aC.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick1_s1.in.detect = function() {return log_valued('brick1_s1.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick1_s1.status_')];}, new dzn.itouch().status_to_string)};
  m.brick1_s2.in.detect = function() {return log_valued('brick1_s2.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick1_s2.status_')];}, new dzn.itouch().status_to_string)};
  m.brick1_s3.in.detect = function() {return log_valued('brick1_s3.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick1_s3.status_')];}, new dzn.itouch().status_to_string)};
  m.brick1_s4.in.detect = function() {return log_valued('brick1_s4.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick1_s4.status_')];}, new dzn.itouch().status_to_string)};
  m.brick2_aA.in.move = function() {log_in('brick2_aA.', 'move', e);};
  m.brick2_aA.in.run = function() {log_in('brick2_aA.', 'run', e);};
  m.brick2_aA.in.stop = function() {log_in('brick2_aA.', 'stop', e);};
  m.brick2_aA.in.coast = function() {log_in('brick2_aA.', 'coast', e);};
  m.brick2_aA.in.zero = function() {log_in('brick2_aA.', 'zero', e);};
  m.brick2_aA.in.position = function() {log_in('brick2_aA.', 'position', e);};
  m.brick2_aA.in.at = function() {return log_valued('brick2_aA.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick2_aA.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick2_aB.in.move = function() {log_in('brick2_aB.', 'move', e);};
  m.brick2_aB.in.run = function() {log_in('brick2_aB.', 'run', e);};
  m.brick2_aB.in.stop = function() {log_in('brick2_aB.', 'stop', e);};
  m.brick2_aB.in.coast = function() {log_in('brick2_aB.', 'coast', e);};
  m.brick2_aB.in.zero = function() {log_in('brick2_aB.', 'zero', e);};
  m.brick2_aB.in.position = function() {log_in('brick2_aB.', 'position', e);};
  m.brick2_aB.in.at = function() {return log_valued('brick2_aB.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick2_aB.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick2_s2.in.detect = function() {return log_valued('brick2_s2.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick2_s2.status_')];}, new dzn.itouch().status_to_string)};
  m.brick2_s3.in.detect = function() {return log_valued('brick2_s3.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick2_s3.status_')];}, new dzn.itouch().status_to_string)};
  m.brick2_s4.in.detect = function() {return log_valued('brick2_s4.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick2_s4.status_')];}, new dzn.itouch().status_to_string)};
  m.brick3_aA.in.move = function() {log_in('brick3_aA.', 'move', e);};
  m.brick3_aA.in.run = function() {log_in('brick3_aA.', 'run', e);};
  m.brick3_aA.in.stop = function() {log_in('brick3_aA.', 'stop', e);};
  m.brick3_aA.in.coast = function() {log_in('brick3_aA.', 'coast', e);};
  m.brick3_aA.in.zero = function() {log_in('brick3_aA.', 'zero', e);};
  m.brick3_aA.in.position = function() {log_in('brick3_aA.', 'position', e);};
  m.brick3_aA.in.at = function() {return log_valued('brick3_aA.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick3_aA.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick3_aC.in.move = function() {log_in('brick3_aC.', 'move', e);};
  m.brick3_aC.in.run = function() {log_in('brick3_aC.', 'run', e);};
  m.brick3_aC.in.stop = function() {log_in('brick3_aC.', 'stop', e);};
  m.brick3_aC.in.coast = function() {log_in('brick3_aC.', 'coast', e);};
  m.brick3_aC.in.zero = function() {log_in('brick3_aC.', 'zero', e);};
  m.brick3_aC.in.position = function() {log_in('brick3_aC.', 'position', e);};
  m.brick3_aC.in.at = function() {return log_valued('brick3_aC.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick3_aC.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick3_s1.in.turnon = function() {log_in('brick3_s1.', 'turnon', e);};
  m.brick3_s1.in.turnoff = function() {log_in('brick3_s1.', 'turnoff', e);};
  m.brick3_s1.in.detect = function() {return log_valued('brick3_s1.', 'detect', e, function(s) {return new dzn.ilight().status[drop_prefix(s, 'brick3_s1.status_')];}, new dzn.ilight().status_to_string)};
  m.brick3_s2.in.detect = function() {return log_valued('brick3_s2.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick3_s2.status_')];}, new dzn.itouch().status_to_string)};
  m.brick3_s3.in.detect = function() {return log_valued('brick3_s3.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick3_s3.status_')];}, new dzn.itouch().status_to_string)};
  m.brick4_aA.in.move = function() {log_in('brick4_aA.', 'move', e);};
  m.brick4_aA.in.run = function() {log_in('brick4_aA.', 'run', e);};
  m.brick4_aA.in.stop = function() {log_in('brick4_aA.', 'stop', e);};
  m.brick4_aA.in.coast = function() {log_in('brick4_aA.', 'coast', e);};
  m.brick4_aA.in.zero = function() {log_in('brick4_aA.', 'zero', e);};
  m.brick4_aA.in.position = function() {log_in('brick4_aA.', 'position', e);};
  m.brick4_aA.in.at = function() {return log_valued('brick4_aA.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick4_aA.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick4_aB.in.move = function() {log_in('brick4_aB.', 'move', e);};
  m.brick4_aB.in.run = function() {log_in('brick4_aB.', 'run', e);};
  m.brick4_aB.in.stop = function() {log_in('brick4_aB.', 'stop', e);};
  m.brick4_aB.in.coast = function() {log_in('brick4_aB.', 'coast', e);};
  m.brick4_aB.in.zero = function() {log_in('brick4_aB.', 'zero', e);};
  m.brick4_aB.in.position = function() {log_in('brick4_aB.', 'position', e);};
  m.brick4_aB.in.at = function() {return log_valued('brick4_aB.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick4_aB.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick4_aC.in.move = function() {log_in('brick4_aC.', 'move', e);};
  m.brick4_aC.in.run = function() {log_in('brick4_aC.', 'run', e);};
  m.brick4_aC.in.stop = function() {log_in('brick4_aC.', 'stop', e);};
  m.brick4_aC.in.coast = function() {log_in('brick4_aC.', 'coast', e);};
  m.brick4_aC.in.zero = function() {log_in('brick4_aC.', 'zero', e);};
  m.brick4_aC.in.position = function() {log_in('brick4_aC.', 'position', e);};
  m.brick4_aC.in.at = function() {return log_valued('brick4_aC.', 'at', e, function(s) {return new dzn.imotor().result_t[drop_prefix(s, 'brick4_aC.result_t_')];}, new dzn.imotor().result_t_to_string)};
  m.brick4_s1.in.detect = function() {return log_valued('brick4_s1.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick4_s1.status_')];}, new dzn.itouch().status_to_string)};
  m.brick4_s2.in.detect = function() {return log_valued('brick4_s2.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick4_s2.status_')];}, new dzn.itouch().status_to_string)};
  m.brick4_s3.in.detect = function() {return log_valued('brick4_s3.', 'detect', e, function(s) {return new dzn.itouch().status[drop_prefix(s, 'brick4_s3.status_')];}, new dzn.itouch().status_to_string)};
  return e;
}

function main () {
  var loc = new dzn.locator();
  var rt = new dzn.runtime(function() {console.error("illegal");process.exit(0);});
  var sut = new dzn.LegoBallSorter(loc.set(rt), {name: 'sut'});

  var event_map = LegoBallSorter_fill_event_map(sut);

  var fs = require ('fs');
  lines = fs.readFileSync ('/dev/stdin', 'ascii').toString().trim().split ('\n').reverse ();
  var event;
  while (event = read_line ()) {
    if (event_map[event]) {
      event_map[event]();
    }
  }
}

main ();
