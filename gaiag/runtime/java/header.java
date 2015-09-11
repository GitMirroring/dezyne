// Dezyne --- Dezyne command line tools
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

// header
//package dezyne;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

class V<T> {
  T v;
  public V (T v) {this.v = v;}
}

@FunctionalInterface
interface Action {
  public abstract void action();
}

@FunctionalInterface
interface Action1<P> {
  public abstract void action(P p);
}

@FunctionalInterface
interface Action2<P0,P1> {
  public abstract void action(P0 p0, P1 p1);
}

@FunctionalInterface
interface Action3<P0,P1,P2> {
  public abstract void action(P0 p0, P1 p1, P2 p2);
}

@FunctionalInterface
interface Action4<P0,P1,P2,P3> {
  public abstract void action(P0 p0, P1 p1, P2 p2, P3 p3);
}

@FunctionalInterface
interface Action5<P0,P1,P2,P3,P4> {
  public abstract void action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4);
}

@FunctionalInterface
interface Action6<P0,P1,P2,P3,P4,P5> {
  public abstract void action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4, P5 p5);
}

@FunctionalInterface
interface ValuedAction<R> {
  public abstract R action();
}

@FunctionalInterface
interface ValuedAction1<R,P> {
  public abstract R action(P p);
}

@FunctionalInterface
interface ValuedAction2<R,P0,P1> {
  public abstract R action(P0 p0, P1 p1);
}

@FunctionalInterface
interface ValuedAction3<R,P0,P1,P2> {
  public abstract R action(P0 p0, P1 p1, P2 p2);
}

@FunctionalInterface
interface ValuedAction4<R,P0,P1,P2,P3> {
  public abstract R action(P0 p0, P1 p1, P2 p2, P3 p3);
}

@FunctionalInterface
interface ValuedAction5<R,P0,P1,P2,P3,P4> {
  public abstract R action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4);
}

@FunctionalInterface
interface ValuedAction6<R,P0,P1,P2,P3,P4,P5> {
  public abstract R action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4, P5 p5);
}

@SuppressWarnings("unchecked")
abstract class Interface<I extends Interface.In, O extends Interface.Out> {
  abstract class Port {
    public String name;
    public Component self;
  }
  abstract class In extends Port {
  }
  abstract class Out extends Port {
  }
  public I in;
  public O out;
  @SuppressWarnings("rawtypes")
    public static void connect(Interface provided, Interface required) {
    provided.out = required.out;
    required.in = provided.in;
  }
}

abstract class ComponentBase {
  public Locator locator;
  public Runtime runtime;
  public SystemComponent parent;
  public String name;
  @SuppressWarnings("unchecked")
  public ComponentBase(Locator locator, String name, SystemComponent parent) {this.locator = locator; this.parent = parent; this.name = name; this.runtime = (Runtime)locator.get(Runtime.class); this.runtime.components.add(this);};
}

abstract class Component extends ComponentBase {
  public boolean handling;
  public boolean flushes;
  public Component deferred;
  public Queue<Action> q;
  public Component(Locator locator, String name, SystemComponent parent) {super(locator, name, parent); this.q = new LinkedList<Action>();};
}

abstract class SystemComponent extends ComponentBase {
  public SystemComponent(Locator locator, String name, SystemComponent parent) {super(locator, name, parent);};
}

class Meta {
  public Interface i;
  public String e;
  public Meta(Interface i, String e) {this.i = i; this.e = e;}
}

class Runtime<R> {
  public List<ComponentBase> components;
  {
    this.components = new ArrayList<ComponentBase> ();
  }
  public Action illegal;
  public Runtime() {this(new Action() {public void action() {throw new RuntimeException("illegal");}});}
  public Runtime(Action illegal) {this.illegal = illegal;}
  public static boolean external(Component c) {
    return !c.runtime.components.contains(c);
  }
  public static void flush(Component c) {
    if (!external(c)) {
      while (!c.q.isEmpty()) {
        handle(c, c.q.remove());
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
    if (!(i != null && i.flushes) && !o.handling) {
      handle(o, f);
    }
    else {
      o.q.add(f);
      if (i != null) {
        i.deferred = o;
      }
    }
  }
  public static <R extends Enum<R>> R valued_helper(Component c, ValuedAction<R> f, Meta m) throws RuntimeException {
    if (c.handling) {
      throw new RuntimeException("a valued event cannot be deferred");
    }
    c.handling = true;
    R r = f.action();
    c.handling = false;
    flush(c);
    return r;
  };
  public static void handle(Component c, Action f) {
    if (!c.handling) {
      c.handling = true;
      f.action();
      c.handling = false;
      flush(c);
    }
    else {
      throw new RuntimeException("component already handling an event");
    }
  }
  public static void callIn(Component c, Action f, Meta m) {
    traceIn(m.i, m.e);
    handle(c, f);
    traceOut(m.i, "return");
  }
  public static <R extends Enum<R>> R callIn(Component c, ValuedAction<R> f, Meta m) throws RuntimeException {
    traceIn(m.i, m.e);
    R r = valued_helper(c, f, m);
    traceOut(m.i, r.getClass().getSimpleName() + "_" + r.name());
    return r;
  }
  public static void callOut(Component c, Action f, Meta m) {
    traceOut(m.i, m.e);
    defer(m.i.in.self, c, f);
  }
  public static String path(ComponentBase o, String p) {
    if (o == null) {
      return "<external>." + p;
    }
    if (o.parent != null) {
      return path(o.parent, o.name + (p.isEmpty() ? p : ".") + p);
    }
    return o.name + (p.isEmpty() ? p : ".") + p;
  }
  public static String path(Interface.Port o) {
    return path(o, "");
  }
  public static String path(Interface.Port o, String p) {
    return path(o.self, (o.name == null ? "" : o.name) + (p.isEmpty() ? p : ".") + p);
  }
  public static void traceIn(Interface i, String e) {
    System.err.println(path(i.out) + "." + e + " -> "
                       + path(i.in) + "." + e);
  }
  public static void traceOut(Interface i, String e) {
    System.err.println(path(i.in) + "." + e + " -> "
                       + path(i.out) + "." + e);
  }
}

class Locator {
  private static class Services extends HashMap<String, Object> {Services(){}Services(Services o){super(o);}}
  Services services;
  Locator() {this(new Services());}
  Locator(Services services) {this.services = services;}
  static String key(Object o, String key) {
    Class c = (o instanceof Class) ? (Class)o : o.getClass();
    return c.getName() + key;
  }
  public Locator set(Object o) {return set(o, "");}
  public Locator set(Object o, String key) {
    services.put(this.key(o,key), o);
    return this;
  }
  @SuppressWarnings("unchecked")
  public Object get(Object o) {return get(o, "");}
  @SuppressWarnings("unchecked")
  public Object get(Object o, String key) {
    Class c = (o instanceof Class) ? (Class)o : o.getClass();
    return services.get(this.key(c, key));
  }
  public Locator clone() {return new Locator(new Services(services));}
}

// end header
