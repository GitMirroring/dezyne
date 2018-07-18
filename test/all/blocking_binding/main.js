// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

assert = require ('assert');
var dzn = typeof (dzn) !== undefined && dzn ? dzn : require (__dirname + '/dzn/runtime');

dzn.extend (dzn, require (__dirname + '/dzn/blocking_binding'));

var relaxed = false;
var lines = [];
function read_line() {
  if (lines.length) {
    return lines.pop();
  }
  return '';
}

function peek_line() {
  return lines.slice(-1)[0];
}

function drop_prefix(string, prefix) {
  if (string.indexOf(prefix) === 0) {
    return string.slice(prefix.length);
  }
  return string;
}

function consume_synchronous_out_events(prefix, event, event_map) {
  var s;
  while (s = read_line()) if (s === prefix + event) break;
  while (s = read_line()) {
    if (!event_map[s]) {
      break;
    }
    event_map[s]();
  }
  return s && s.split ('.').last ();
}

function log_in(prefix, event, event_map) {
  console.error(prefix + event);
  if (relaxed) return;
  consume_synchronous_out_events(prefix, event, event_map);
  console.error(prefix + 'return');
}

function log_out(prefix, event) {
  console.error(prefix + event);
}

function type_helper(value, type) {
  if (type === 'int') return parseInt (value);
  if (type === 'bool') return value === 'false' ? false : true;
  return value;
}

function log_valued(prefix, event, event_map) {
  console.error(prefix + event);
  if (relaxed) return 0;
  var s = consume_synchronous_out_events(prefix, event, event_map);
  if (s !== undefined) {
    console.error(prefix + s);
    return s;
  }
  throw 'runtime error: "' + s + '" is not a reply value'
}

function blocking_binding_fill_event_map(m)
{
  var c = new dzn.component(m._dzn.locator, {provides:{}});
  c._dzn.flushes = dzn.flush;

  var e = {
    'p.e': function () {var v = {value:0}; m.p.in.e(v); assert(v.value == 456);},
    'r.cb': function () {m.r.out.cb();},
  };
  if (dzn.flush) {
    m.p._dzn.meta.requires.component = c;
    m.p._dzn.meta.requires.name = '<internal>.p';
  }

  if (dzn.flush) {
    m.r._dzn.meta.provides.component = c;
    m.r._dzn.meta.provides.name = '<internal>.r';
  }
  e['r.<flush>'] = function() {console.error('r.<flush>'); m._dzn.rt.flush(m.r._dzn.meta.provides.component);};

  m.r.in.e = function() {log_in('r.', 'e', e);};

  m.p._dzn.meta.provides.name = "p";
  m.p._dzn.meta.requires.name = "p";
  m.r._dzn.meta.provides.name = "r";
  m.r._dzn.meta.requires.name = "r";

  return e;
}

function main () {
  dzn.flush = process.argv.length > 2 && process.argv[2] === '--flush';
  dzn.relaxed = process.argv.length > 2 && process.argv[2] === '--relaxed';
  var loc = new dzn.locator();
  var pump = new dzn.pump();
  loc.set(pump);
  var rt = new dzn.runtime(function() {console.error('illegal');process.exit(0);});
  var sut = new dzn.blocking_binding(loc.set(rt), {name:'sut'});

  var event_map = blocking_binding_fill_event_map(sut);

  var fs = require ('fs');
  lines = fs.readFileSync('/dev/stdin', 'ascii').toString().trim().split ('\n').reverse ();
  var s;
  pump.queue = {pop:function(){var s=read_line(); return s?event_map[s]:undefined;},peek:peek_line};
  while (s = pump.queue.peek ()) {
    if (event_map[s]) {
      pump.pump (event_map[s]);
    }
  }
}

main ();
