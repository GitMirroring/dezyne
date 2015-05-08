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

function runtime(illegal) {
  this.illegal = illegal || function() {console.assert(!'illegal')};

  this.path = function(m, p) {
    p = p ? p : '';
    if (!m || !m.name) {
      return '<external>.' + p;
    }
    if (m.component) {
      return this.path(m.component.meta, m.name + (p ? '.' + p : p));
    }
    if ('component' in m) {
      return '<external>.' + m.name + (p ? '.' + p : p);
    }
    if (m.parent) {
      return this.path(m.parent.meta, m.name + (p ? '.' + p : p));
    }
    return m.name + (p ? '.' + p : p);
  };

  this.external = function(c) {
    return c.rt.components.indexOf (c) == -1;
  };

  this.flush = function(c) {
    if (this.external(c)) {
      return;
    }
    while (c.queue && c.queue.length) {
      this.handle(c, c.queue.pop());
    }
    if (c.deferred) {
      var t = c.deferred;
      c.deferred = null;
      if (!t.handling) {
        this.flush(t);
      }
    }
  };

  this.defer = function(i, o, f) {
    if(!i || (!i.flushes && !o.handling)) {
      this.handle(o, f);
    }
    else {
      i.deferred = o;
      o.queue = [f].concat (o.queue || []);
    }
  };

  this.handle = function(c, f) {
    if (!c.handling) {
      {
        c.handling = true;
        f();
        c.handling = false;
      }
      this.flush(c);
    }
    else {
      throw 'component already handling an event';
    }
  };

  this.trace_in = function(m, e) {
    process.stderr.write(this.path(m[0].meta.requires) + '.' + e + ' -> '
                         + this.path(m[0].meta.provides) + '.' + e + '\n');
  };

  this.trace_out = function(m, e) {
    process.stderr.write(this.path(m[0].meta.provides) + '.' + e + ' -> '
                         + this.path(m[0].meta.requires) + '.' + e + '\n');
  };

  this.call_in = function(c, f, m) {
    this.trace_in(m, m[1]);
    var handle = c.handling;
    c.handling = true;
    var r = f();
    if (handle) {
      throw 'a valued event cannot be deferred';
    }
    c.handling = false;
    this.flush(c);
    this.trace_out(m, r === undefined ? 'return' : m[2][r]);
    return r;
  };

  this.call_out = function(c, f, m) {
    this.trace_out(m, m[1]);
    this.defer(m[0].meta.provides.component, c, f);
  };
};

function locator (services) {
  this.services = services || {};
  this.key = function(type, key) {
    return (type.prototype ? type.prototype : type).name + (key || '');
  };
  this.set = function(o, key) {
    this.services[this.key(o, key)] = o;
    return this;
  };
  this.get = function(o, key) {
    return this.services[this.key(o, key)];
  };
  this.clone = function() {
    c = {}
    Object.keys(this.services).forEach(function (k,v) {c[k]=v;});
    return new dezyne.locator(c);
  };
};

function connect(provided, required) {
  provided.out = required.out;
  required.in = provided.in;
  provided.meta.requires = required.meta.requires;
  required.meta.provides = provided.meta.provides;
};

var dezyne = {connect:connect,locator:locator,runtime:runtime};
