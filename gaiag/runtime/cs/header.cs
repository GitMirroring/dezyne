// Dezyne --- Dezyne command line tools
//
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
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

// -*-java-*-

using System;
using System.Collections.Generic;
using System.Diagnostics;

public class V<T> where T : new()
{
    public T v;
    public V() { this.v = new T(); }
    public V(T v) { this.v = v; }
}

public class RuntimeException : SystemException {
  public RuntimeException(String msg) : base(msg) {}
};

namespace dzn {
  public class Meta {
    public String name;
    public Meta parent;
    public Meta (String name="", Meta parent=null) {this.name=name;this.parent=parent;}

  };
  namespace port {
    public class Meta {
      public class Provides {
        public String name = null;
        public Component component;
        public dzn.Meta meta = new dzn.Meta();
      };
      public Provides provides = new Provides();
      public class Requires {
        public String name = null;
        public Component component;
        public dzn.Meta meta = new dzn.Meta();
      };
      public Requires requires = new Requires();
    };
  };
};

abstract public class Interface<I,O> where I: Interface<I,O>.In where O : Interface<I,O>.Out {
  public dzn.port.Meta dzn_meta;
  abstract public class Port {
  }
  abstract public class In : Port {
  }
  abstract public class Out : Port {
  }
  private In in_;
  private Out out_;
  public I inport {
    get { return (I) in_; }
    set { this.in_ = value; }
  }
  public O outport {
    get { return (O) out_; }
    set { this.out_ = value; }
  }
}

abstract public class ComponentBase {
  public Locator locator;
  public Runtime runtime;
  public dzn.Meta dzn_meta;
  public ComponentBase(Locator locator, String name, dzn.Meta parent) {this.locator = locator; this.dzn_meta = new dzn.Meta (name, parent); this.runtime = locator.get<Runtime>(); this.runtime.components.Enqueue(this);}
}

public class Component : ComponentBase {
  public bool handling;
  public bool flushes;
  public Component deferred;
  public Queue<Action> q;
  public Component(Locator locator, String name="", dzn.Meta parent=null)
    : base(locator, name, parent)
    {this.q = new Queue<Action>();}
}

abstract public class SystemComponent : ComponentBase {
  public SystemComponent(Locator locator, String name, dzn.Meta parent)
    : base(locator, name, parent)
    {}
}

public class Runtime {
  public Queue<ComponentBase> components;
  public Action illegal;
  public Runtime (Action illegal=null) {
    if (illegal == null) {
      illegal = () => {throw new RuntimeException("illegal");};
    }
    this.illegal = illegal;
    this.components = new Queue<ComponentBase> ();
  }
  public static bool external(Component c) {
    return !c.runtime.components.Contains(c);
  }
  public static void flush(Component c) {
    if (!external(c)) {
      while (c.q.Count > 0) {
        handle(c, c.q.Dequeue());
      }
      if (c.deferred != null) {
        Component t = c.deferred;
        c.deferred = null;
        if (!t.handling) {
          flush(t);
        }
      }
    }
  }
  public static void defer(Component i, Component o, Action f) {
    if (!(i !=null && i.flushes) && !o.handling) {
      handle(o, f);
    }
    else {
      o.q.Enqueue(f);
      if (i != null) {
        i.deferred = o;
      }
    }
  }
  public static R valued_helper<R>(Component c, Func<R> f) where R : struct, IComparable, IConvertible, IFormattable {
    if (c.handling) {
      throw new RuntimeException("a valued event cannot be deferred");
    }
    c.handling = true;
    R r = f();
    c.handling = false;
    flush(c);
    return r;
  }
  public static void handle(Component c, Action f) {
    if (!c.handling) {
      c.handling = true;
      f();
      c.handling = false;
      flush(c);
    }
    else {
      throw new RuntimeException("component already handling an event");
    }
  }
  public static void callIn(Component c, Action f, dzn.port.Meta m, String e) {
    traceIn(m, e);
    handle(c, f);
    traceOut(m, "return");
  }
  public static R callIn<R>(Component c, Func<R> f, dzn.port.Meta m, String e) where R : struct, IComparable, IConvertible, IFormattable {
    traceIn(m, e);
    R r = valued_helper(c, f);
    traceOut(m, r.GetType().Name + "_" + Enum.GetName(r.GetType(),r));
    return r;
  }
  public static void callOut(Component c, Action f, dzn.port.Meta m, String e) {
    traceOut(m, e);
    defer(m.provides.component, c, f);
  }
  public static String path(dzn.Meta m, String p="") {
    p = p == "" ? p : "." + p;
    if (m == null) return "<external>" + p;
    if (m.parent == null) return m.name + p;
    return path(m.parent, m.name + p);
  }
  public static void traceIn(dzn.port.Meta m, String e) {
    System.Console.Error.WriteLine(path(m.requires.meta, m.requires.name) + "." + e + " -> "
                                   + path(m.provides.meta, m.provides.name) + "." + e);
  }
  public static void traceOut(dzn.port.Meta m, String e) {
    System.Console.Error.WriteLine(path(m.provides.meta, m.provides.name) + "." + e + " -> "
                                   + path(m.requires.meta, m.requires.name) + "." + e);
  }
}

public class Locator {
  public class Services : Dictionary<String, Object> {public Services(){}public Services(Services o):base(o) {}};
  Services services;
  public Locator():this(new Services()) {}
  public Locator(Services services) {this.services = services;}
  public static String key(Type c, String key) {
    return c.Name + key;
  }
  public static String key(Object o, String key) {
    return Locator.key(o.GetType(), key);
  }
  public Locator set(Object o, String key="") {
    services.Add(Locator.key(o,key), o);
    return this;
  }
  public R get<R>(String key="") {
    return (R)services[Locator.key(typeof(R), key)];
  }
  public Locator clone() {return new Locator(new Services(services));}
}
