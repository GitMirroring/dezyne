// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
// Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

if (!Array.prototype.each) {
  Array.prototype.each = Array.prototype.forEach;
};

if (!Array.prototype.find) {
  Array.prototype.find = function(predicate) {
    if (this === null) {
      throw new TypeError('Array.prototype.find called on null or undefined');
    }
    if (typeof predicate !== 'function') {
      throw new TypeError('predicate must be a function');
    }
    var list = Object(this);
    var length = list.length >>> 0;
    var thisArg = arguments[1];
    var value;

    for (var i = 0; i < length; i++) {
      value = list[i];
      if (predicate.call(thisArg, value, i, list)) {
        return value;
      }
    }
    return undefined;
  };
}

if (!Array.prototype.last) {
  Array.prototype.last = function (){
    return this[this.length - 1];
  };
};

if (!Array.prototype.remove) {
  Array.prototype.remove = function (elem) {
    var i = this.indexOf(elem);
    if(i != -1)
      this.splice(i, 1);
    return this;
  };
};

if (!Function.prototype.runtime) {
  Function.prototype.runtime = function (o, port, direction, name) {
    var f = this.bind (o);
    return function () {
      var args = Array.prototype.slice.call (arguments);
      var ff = function () {
        return f.apply (o, args);
      }.bind (this)
      return o._dzn.rt['call_' + direction] (o, ff, [port, name]);
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
    if (m.parent) return this.path(m.parent._dzn.meta, m.name + p, 'x');
    if (!m.component && !p) return '<external>' + (m.name ? '.' + m.name : '');
    if (!m.component) return (m.name ? m.name : '<external>') + p;
    return this.path(m.component._dzn.meta, m.name + p, 'x');
  };

  this.external = function(c) {
    return c._dzn.rt.components.indexOf (c) == -1;
  };

  this.flush = function(c) {
    if (this.external(c)) {
      return;
    }
    while (c.queue && c.queue.length) {
      this.handle(c, c.queue.pop());
    }
    if (c._dzn.deferred) {
      var t = c._dzn.deferred;
      c._dzn.deferred = null;
      if (!t._dzn.handling) {
        this.flush(t);
      }
    }
  };

  this.defer = function(i, o, f) {
    if(!(i && i._dzn.flushes) && !o._dzn.handling) {
      this.handle(o, f);
    }
    else {
      o.queue = [f].concat (o.queue || []);
      if (i) {
        i._dzn.deferred = o;
      }
    }
  };

  this.collateral_block = function (locator) {
    var p;
    if (p = locator.get(new pump())) {p.collateral_block();}
  }.bind (this);

  this.handle = function(c, f) {
    if (c._dzn.handling) this.collateral_block (c._dzn.locator);
    if (c._dzn.handling)
      throw new Error ('runtime error: component already handling an event: ' + c._dzn.meta.name);
    c._dzn.handling = true;
    var r = f();
    c._dzn.handling = false;
    this.flush(c);
    return r;
  };

  this.trace = function(m, e, trace) {
    trace(this.path(m[0]._dzn.meta.requires) + '.' + e + ' -> '
          + this.path(m[0]._dzn.meta.provides) + '.' + e + '\n');
  };

  this.trace_out = function(m, e, trace) {
    trace(this.path(m[0]._dzn.meta.requires) + '.' + e + ' <- '
          + this.path(m[0]._dzn.meta.provides) + '.' + e + '\n');
  };

  this.trace_qin = function(m, e, trace) {
    trace(this.path(m[0]._dzn.meta.requires, '<q>') + ' <- '
          + this.path(m[0]._dzn.meta.provides) + '.' + e + '\n');
  };

  this.trace_qout = function(m, e, trace) {
    trace(this.path(m[0]._dzn.meta.requires) + '.' + e + ' <- '
          + this.path(m[0]._dzn.meta.provides, '<q>') + '\n');
  };

  this.call_in = function(c, f, m) {
    var trace = c._dzn.locator.get(Function.prototype, 'trace');
    this.trace(m, m[1], trace);
    var r = this.handle(c, f);
    this.trace_out(m, (r === undefined ? 'return' : r), trace);
    return r;
  }

  this.call_out = function(c, f, m) {
    var trace = c._dzn.locator.get(Function.prototype, 'trace');
    this.trace_qin(m, m[1], trace);
    this.defer(m[0]._dzn.meta.provides.component, c, f);
  };

  this.bind = function (o) {
    o._dzn.meta.ports
      .each (function (name) {
        var port = o[name];
        var dir = Object.keys (port._dzn.meta.provides).length ? 'in' : 'out';
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

runtime.init = function (o, locator, meta) {
  o._dzn = {};
  o._dzn.locator = locator;
  o._dzn.rt = locator.get (new runtime());
  o._dzn.rt.components = (o._dzn.rt.components || []).concat ([o]);
  o._dzn.meta = meta;
};

function identity (x) {return x;}
function debug_print (msg, id) {if (true) console.log ('[' + id + '] ' + msg);}
var debug = identity;

var fibers = function (f) {
  function identity (x){return x;};
  return {yield:identity,run:identity}
}
if (typeof (module) !== 'undefined') {
  try {fibers = require ('fibers') } catch (e) { }
}

function pump() {
  this.id = 0;
  this.zero = {id:this.id};
  this.self = {id:this.id};
  this.running = false;
  this.skip_block = [];
  this.coroutines = [];
  this.collateral_blocked = [];
  this.queue = {pop:function (){},peek:function (){}};

  this.at = function (id) {
    return this.coroutines.find (function (c){return c.id == id;});
  }.bind (this);

  this.worker = function () {
    var event;
    if (event = this.queue.pop ())
      return event ();
  }.bind (this);

  this.create_context = function () {
    var id = this.id++;
    var coroutine = {id:id};
    var f = function (self) {
      var r;
      debug('create context', self.id);
      while ((this.running || this.queue.peek ()) && !self.released) {
        this.worker ();
        if (!self.released) this.collateral_release (self);
        if (self.released) self.finished = true;
        if (this.switch_context) this.switch_context ();
        if (!self.released) this.collateral_release (self);
      }
    }.bind (this);

    this.coroutines.push (coroutine);
    coroutine.fiber = fibers (f);
    return coroutine;
  }.bind (this);

  this.collateral_block = function () {
    var self = this.self;
    debug('collateral_block', self.id);
    this.collateral_blocked.push (self);
    var coroutine = this.create_context ();
    this.coroutines = this.coroutines.filter (function (c){return c.id!=coroutine.id;});
    fibers.yield (coroutine);
    debug('collateral_unblock', self.id);
  }.bind (this);

  this.collateral_release = function (self) {
    if (this.collateral_blocked.length) self.finished = true;
    while (this.collateral_blocked.length) {
      this.coroutines.push (this.collateral_blocked.shift ());
      fibers.yield (this.coroutines.last ());
    }
  }.bind (this);

  this.block = function (port) {
    var skip = this.skip_block.indexOf (port);
    if (skip !== -1) {
      this.skip_block = this.skip_block.slice (0, skip)
        .concat (this.skip_block.slice (skip+1));
      return;
    }
    var self = this.self;
    debug('block', self.id);
    self.port = port;
    fibers.yield (this.create_context ());
    debug('entered context', this.self.id);
  }.bind (this);

  this.release = function (port) {
    var self = this.self;
    debug('release', self.id);

    var blocked = this.coroutines.find (function (c){return c.port == port;});
    if (!blocked) {
      debug('skip block', self.id);
      this.skip_block.push(port);
      return;
    }

    debug('unblock', blocked.id);
    debug('released', self.id);
    self.released = true;

    this.switch_context = function () {
      delete this.switch_context;
      delete blocked.port;
      debug('switch from', self.id);
      debug('to', blocked.id);
      fibers.yield (blocked);
    }.bind (this);
  }.bind (this);

  this.pump = function() {
    var from = {id:-1};
    this.zero = this.create_context ();
    var to = this.zero;
    while(this.queue.peek () && to != undefined) { //? || this.running) {
      debug('switch_to ' + to.id, from.id);
      from = to;
      this.self = to;
      to = to.fiber.run(to);
      if(to === undefined) {
        this.coroutines = this.coroutines.filter (function (c){return c.id != from.id;})
        if (!this.coroutines.length) return;
        to = this.coroutines.last ();
      }
    }
  }.bind(this);
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
  provided._dzn.meta.requires = required._dzn.meta.requires;
  required._dzn.meta.provides = provided._dzn.meta.provides;
};

function component (locator, meta) {
  this._dzn = {};
  this._dzn.locator = locator;
  this._dzn.rt = locator.get(new runtime());
  this._dzn.rt.components = (this._dzn.rt.components || []).concat ([this]);
  this._dzn.meta = meta;
  this._dzn.flushes = true;
}

function check_bindings(component) {
  component._dzn.meta.ports.map(function(p){
    if(!component[p]) throw new Error(component._dzn.meta.name + '.' + p + ' not connected');
    Object.keys(component[p].in).map(function(e){if(!component[p].in[e]) throw new Error(component._dzn.meta.name + '.' + p + '.in.' + e + ' not connected');});
    Object.keys(component[p].out).map(function(e){if(!component[p].out[e]) throw new Error(component._dzn.meta.name + '.' + p + '.out.' + e + ' not connected');});
  });
  if (component._dzn.meta.children) component._dzn.meta.children.map(function(c){check_bindings(component[c]);});
}

var dzn = extend (typeof (dzn !== 'undefined') && dzn ? dzn : {}, {
  check_bindings: check_bindings,
  component: component,
  connect: connect,
  extend: extend,
  locator: locator,
  pump: pump,
  runtime: runtime,
});

function main () {
  debug = debug_print;
  var p = new dzn.pump ();
  var q = [
    function () {
      console.log ('one')
      p.block ('one');
      console.log ('one.done')
    },
    function () {
      console.log ('two')
      p.collateral_block ();
      console.log ('two.done')
    },
    function () {
      console.log ('three')
      p.release ('one');
      console.log ('three.done')
    },
  ].reverse ();
  p.queue = {
    pop: function (f) {return q.pop ();}
    ,
    peek: function () {return q.length;}
  };
  fibers (p.pump).run ();
}

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
  if (require.main === module && /runtime.js/.test (require.main.filename))
    main ();
}
