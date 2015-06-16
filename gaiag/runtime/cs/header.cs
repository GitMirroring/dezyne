// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

public class V<T> {
  public T v;
  public V (T v) {this.v = v;}
}

public class RuntimeException : SystemException {
  public RuntimeException(String msg) : base(msg) {}
};

abstract public class Interface<I,O> where I: Interface<I,O>.In where O : Interface<I,O>.Out {
  abstract public class Port {
    public String name;
    public Component self;
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
  public SystemComponent parent;
  public String name;
  public ComponentBase(Locator locator, String name, SystemComponent parent) {this.locator = locator; this.parent = parent; this.name = name; this.runtime = locator.get<Runtime>(); this.runtime.components.Enqueue(this);}
}

abstract public class Component : ComponentBase {
  public bool handling;
  public bool flushes;
  public Component deferred;
  public Queue<Action> q;
  public Component(Locator locator, String name, SystemComponent parent)
    : base(locator, name, parent)
    {this.q = new Queue<Action>();}
}

abstract public class SystemComponent : ComponentBase {
  public SystemComponent(Locator locator, String name, SystemComponent parent)
    : base(locator, name, parent)
    {}
}

public class Meta<I,O> where I: Interface<I,O>.In where O : Interface<I,O>.Out {
  public Interface<I,O> i;
  public String e;
  public Meta(Interface<I,O> i, String e) {this.i = i; this.e = e;}
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
  public static R valued_helper<I,O,R>(Component c, Func<R> f, Meta<I,O> m) where I: Interface<I,O>.In where O : Interface<I,O>.Out where R : struct, IComparable, IConvertible, IFormattable {
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
  public static void callIn<I,O>(Component c, Action f, Meta<I,O> m) where I: Interface<I,O>.In where O : Interface<I,O>.Out {
    traceIn(m.i, m.e);
    handle(c, f);
    traceOut(m.i, "return");
  }
  public static R callIn<I,O,R>(Component c, Func<R> f, Meta<I,O> m) where I: Interface<I,O>.In where O : Interface<I,O>.Out where R : struct, IComparable, IConvertible, IFormattable {
    traceIn(m.i, m.e);
    R r = valued_helper(c, f, m);
    traceOut(m.i, r.GetType().Name + "_" + Enum.GetName(r.GetType(),r));
    return r;
  }
  public static void callOut<I,O>(Component c, Action f, Meta<I,O> m) where I: Interface<I,O>.In where O : Interface<I,O>.Out {
    traceOut(m.i, m.e);
    defer(m.i.inport.self, c, f);
  }
  public static String path(ComponentBase o, String p) {
    if (o == null) {
      return "<external>." + p;
    }
    if (o.parent != null) {
      return path(o.parent, o.name + (p == "" ? p : ".") + p);
    }
    return o.name + (p == "" ? p : ".") + p;
  }
  public static String path<I,O>(Interface<I,O>.Port o, String p="") where I: Interface<I,O>.In where O : Interface<I,O>.Out {
    return path(o.self, (o.name == null ? "" : o.name) + (p == "" ? p : ".") + p);
  }
  public static void traceIn<I,O>(Interface<I,O> i, String e) where I: Interface<I,O>.In where O : Interface<I,O>.Out {
    System.Console.Error.WriteLine(path(i.outport) + "." + e + " -> "
                                   + path(i.inport) + "." + e);
  }
  public static void traceOut<I,O>(Interface<I,O> i, String e) where I: Interface<I,O>.In where O : Interface<I,O>.Out {
    System.Console.Error.WriteLine(path(i.inport) + "." + e + " -> "
                                 + path(i.outport) + "." + e);
  }
}

public class Locator {
  public class Services : Dictionary<String, Object> {public Services(){}public Services(Services o):base(o) {}};
  Services services;
  public Locator():this(new Services()) {}
  public Locator(Services services) {this.services = services;}
  public static String key(Type c, String key) {
    //System.Console.Error.WriteLine("KEY<TYPE> " + c.Name);
    return c.Name + key;
  }
  public static String key(Object o, String key) {
    //System.Console.Error.WriteLine("KEY<object> " + o.GetType().Name);
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
