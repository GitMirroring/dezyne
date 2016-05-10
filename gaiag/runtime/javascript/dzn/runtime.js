// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

if (!Array.prototype.each) {
  Array.prototype.each = Array.prototype.forEach;
};

if (!Function.prototype.runtime) {
  Function.prototype.runtime = function (o, port, direction, name) {
    var f = this.bind (o);
    return function () {
      var args = Array.prototype.slice.call (arguments);
      var ff = function () {
        return f.apply (o, args);
      }.bind (this)
      o.rt['call_' + direction] (o, ff, [port, name]);
    }
  }
}

function extend(o, u) {
  for (var i in u)
    o[i] = u[i];
  return o;
}

function runtime(illegal) {
  this.illegal = illegal || function() {console.assert(!'illegal')};

  this.path = function(m, p) {
    p = p ? '.' + p : '';
    name = (m && m.name ? '.' + m.name : '')
    if (!m) return '<xternal>' + name + p;
    if (m.parent) return this.path(m.parent.meta, m.name + p, 'x');
    if (!m.component && !p) return '<external>' + (m.name ? '.' + m.name : '');
    if (!m.component) return m.name + p;
    return this.path(m.component.meta, m.name + p, 'x');
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

  this.handle = function(c, f) {
    if (c.handling)
      throw new Error ('runtime error: component already handling an event: ' + c.meta.name);
    c.handling = true;
    var r = f();
    c.handling = false;
    this.flush(c);
    return r;
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
    var r = this.handle(c, f);
    this.trace_out(m, typeof (r) === 'undefined' && 'return' || r, trace);
  }

  this.call_out = function(c, f, m) {
    var trace = c.locator.get(Function.prototype, 'trace');
    this.trace_out(m, m[1], trace);
    this.defer(m[0].meta.provides.component, c, f);
  };

  this.bind = function (o) {
    o.meta.ports
      .each (function (name) {
        var port = o[name];
        var dir = Object.keys (port.meta.provides).length ? 'in' : 'out';
        Object.keys (port[dir])
          .each (function (event) {
            if (port[dir][event])
              port[dir][event] = port[dir][event].runtime (o, port, dir, event);
            else
              console.error ('port not bound:'  + [name, dir, event].join ('.'));
          });
      });
  };
}

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
    return new dzn.locator(extend({}, this.services));
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

function check_bindings(component) {
  component.meta.ports.map(function(p){
    if(!component[p]) throw new Error(component.meta.name + '.' + p + ' not connected');
    Object.keys(component[p].in).map(function(e){if(!component[p].in[e]) throw new Error(component.meta.name + '.' + p + '.in.' + e + ' not connected');});
    Object.keys(component[p].out).map(function(e){if(!component[p].out[e]) throw new Error(component.meta.name + '.' + p + '.out.' + e + ' not connected');});
  });
  component.meta.children.map(function(c){check_bindings(component[c]);});
}

var dzn = extend (typeof (dzn !== 'undefined') && dzn ? dzn : {}, {
  check_bindings: check_bindings,
  component: component,
  connect: connect,
  extend: extend,
  locator: locator,
  runtime: runtime,
});

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
}
