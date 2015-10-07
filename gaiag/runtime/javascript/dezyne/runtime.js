// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

function extend(o, u) {
  for (var i in u)
    o[i] = u[i];
  return o;
}

function runtime(illegal) {
  this.illegal = illegal || function() {console.assert(!'illegal')};

  this.path = function(m, p) {
    p = p ? p : '';
    if (!m || !m.name) {
      return p;
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
    if(!(i && i.flushes) && !o.handling) {
      this.handle(o, f);
    }
    else {
      o.queue = [f].concat (o.queue || []);
      if (i) {
        i.deferred = o;
      }
    }
  };

  this.valued_helper = function(c, f, m) {
    if (c.handling) {
      throw 'runtime error: a valued event cannot be deferred';
    }
    c.handling = true;
    var r = f();
    c.handling = false;
    this.flush(c);
    return r;
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
      throw 'runtime error: component already handling an event';
    }
  };

  this.trace_in = function(m, e, trace) {
      trace(this.path(m[0].meta.requires) + '.' + e + ' -> ' +
            this.path(m[0].meta.provides) + '.' + e + '\n');
  };

  this.trace_out = function(m, e, trace) {
      trace(this.path(m[0].meta.provides) + '.' + e + ' -> ' +
            this.path(m[0].meta.requires) + '.' + e + '\n');
  };

  this.call_in = function(c, f, m) {
    var trace = c.locator.get(Function.prototype, 'trace');
    this.trace_in(m, m[1], trace);
    this.handle(c, f);
    this.trace_out(m, 'return', trace);
  }

  this.rcall_in = function(c, f, m) {
    var trace = c.locator.get(Function.prototype, 'trace');
    this.trace_in(m, m[1], trace);
    var r = this.valued_helper(c, f, m);
    this.trace_out(m, m[2][r], trace);
    return r;
  };

  this.call_out = function(c, f, m) {
    var trace = c.locator.get(Function.prototype, 'trace');
    this.trace_out(m, m[1], trace);
    this.defer(m[0].meta.provides.component, c, f);
  };
};

function locator(services) {
  this.services = services || {};
  this.key = function(type, key) {
    var constructor = type.constructor || (type.prototype && type.prototype.constructor);
    var key = (constructor ? constructor.name : '') + (key || '');
    console.assert(key != '');
    return key;
  };
  this.set = function(o, key) {
    this.services[this.key(o, key)] = o;
    return this;
  };

  this.set(function(s){process.stderr.write(s);}, 'trace');

  this.get = function(o, key) {
    var key = this.key(o, key);
    return this.services[key] || console.assert ('no such service: ' + key);
  };
  this.clone = function() {
    return new dezyne.locator(extend({}, this.services));
  };
};

function connect(provided, required) {
  provided.out = required.out;
  required.in = provided.in;
  provided.meta.requires = required.meta.requires;
  required.meta.provides = provided.meta.provides;
};

function component (locator, meta) {
  this.locator = locator;
  this.rt = locator.get(new runtime());
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;
}

var dezyne = extend (typeof (dezyne !== 'undefined') && dezyne ? dezyne : {}, {
  component: component,
  connect: connect,
  extend: extend,
  locator: locator,
  runtime: runtime,
});

if (typeof (module) !== 'undefined') {
  module.exports = dezyne;
}
