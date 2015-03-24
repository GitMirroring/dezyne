// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#! /usr/bin/nodejs

// handwritten runtime header
var dezyne = {};

dezyne.runtime = function () {
};

var runtime = {
  path : function(m, p) {
    p = p ? p : '';
    if (!m) {
      return 'null.' + p;
    }
    if (m.component) {
      return runtime.path(m.component.meta, m.name + (p ? '.' + p : p));
    }
    if (m.parent) {
      return runtime.path(m.parent.meta, m.name + (p ? '.' + p : p));
    }
    return m.name + (p ? '.' + p : p);
  },

  external : function(c) {
    return false;
  },

  flush : function(c) {
    if (runtime.external(c)) {
      return;
    }
    while (c.queue && c.queue.length) {
      runtime.handle(c, c.queue.pop());
    }
    if (c.deferred) {
      var t = c.deferred;
      c.deferred = null;
      if (!t.handling) {
        runtime.flush(t);
      }
    }
  },

  defer : function(i, o, f) {
    if(runtime.external(i) || runtime.external(o)) {
      runtime.handle(o, f);
    }
    else {
      i.deferred = o;
      o.queue = [f].concat (o.queue || []);
    }
  },

  handle : function(c, f) {
    if (!c.handling) {
      {
        c.handling = true;
        f();
        c.handling = false;
      }
      runtime.flush(c);
    }
    else {
      throw 'component already handling an event';
    }
  },

  trace_in : function(m, e) {
    process.stderr.write(runtime.path(m[0].meta.requires) + '.' + e + ' -> '
                         + runtime.path(m[0].meta.provides) + '.' + e + '\n');
  },

  trace_out : function(m, e) {
    process.stderr.write(runtime.path(m[0].meta.provides) + '.' + e + ' -> '
                         + runtime.path(m[0].meta.requires) + '.' + e + '\n');
  },

  call_in : function(c, f, m) {
    runtime.trace_in(m, m[1]);
    var handle = c.handling;
    c.handling = true;
    var r = f();
    if (handle) {
      throw 'a valued event cannot be deferred';
    }
    c.handling = false;
    runtime.flush(c);
    runtime.trace_out(m, r === undefined ? 'return' : m[2][r]);
    return r;
  },

  call_out : function(c, f, m) {
    runtime.trace_out(m, m[1]);
    runtime.defer(m[0].meta.provides.component, c, f);
  },
};

dezyne.connect = function(provided, required) {
  provided.out = required.out;
  required.in = provided.in;
  provided.meta.requires = required.meta.requires;
  required.meta.provides = provided.meta.provides;
}
// end header
