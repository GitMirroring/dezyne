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
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

class V<T> {
  T v;
  public V (T v) {this.v = v;}
}

abstract class Action {
  public abstract void action();
}

abstract class Action1<P> {
  public abstract void action(P p);
}

abstract class Action2<P0,P1> {
  public abstract void action(P0 p0, P1 p1);
}

abstract class Action3<P0,P1,P2> {
  public abstract void action(P0 p0, P1 p1, P2 p2);
}

abstract class Action4<P0,P1,P2,P3> {
  public abstract void action(P0 p0, P1 p1, P2 p2, P3 p3);
}

abstract class Action5<P0,P1,P2,P3,P4> {
  public abstract void action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4);
}

abstract class Action6<P0,P1,P2,P3,P4,P5> {
  public abstract void action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4, P5 p5);
}

abstract class ValuedAction<R> {
  public abstract R action();
}

abstract class ValuedAction1<R,P> {
  public abstract R action(P p);
}

abstract class ValuedAction2<R,P0,P1> {
  public abstract R action(P0 p0, P1 p1);
}

abstract class ValuedAction3<R,P0,P1,P2> {
  public abstract R action(P0 p0, P1 p1, P2 p2);
}

abstract class ValuedAction4<R,P0,P1,P2,P3> {
  public abstract R action(P0 p0, P1 p1, P2 p2, P3 p3);
}

abstract class ValuedAction5<R,P0,P1,P2,P3,P4> {
  public abstract R action(P0 p0, P1 p1, P2 p2, P3 p3, P4 p4);
}

abstract class ValuedAction6<R,P0,P1,P2,P3,P4,P5> {
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
  public Runtime runtime;
  public SystemComponent parent;
  public String name;
  public ComponentBase(Runtime runtime, String name, SystemComponent parent) {this.runtime = runtime; this.parent = parent; this.name = name; runtime.components.add(this);};
}

abstract class Component extends ComponentBase {
  public boolean handling;
  public boolean flushes;
  public Component deferred;
  public Queue<Action> q;
  public Component(Runtime runtime, String name, SystemComponent parent) {super(runtime, name, parent); this.q = new LinkedList<Action>();};
}

abstract class SystemComponent extends ComponentBase {
  public SystemComponent(Runtime runtime, String name, SystemComponent parent) {super(runtime, name, parent);};
}

class Meta {
  public Interface i;
  public String e;
  public Meta(Interface i, String e) {this.i = i; this.e = e;};
}

class Runtime<R> {
  public List<ComponentBase> components;
  {
    this.components = new ArrayList<ComponentBase> ();
  }
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
    if (i == null || (!i.flushes && !o.handling)) {
      handle(o, f);
    }
    else {
      i.deferred = o;
      o.q.add(f);
    }
  }
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
    boolean handle = c.handling;
    c.handling = true;
    f.action();
    c.handling = false;
    flush(c);
    traceOut(m.i, "return");
  }
  public static <R extends Enum<R>> R callIn(Component c, ValuedAction<R> f, Meta m) throws RuntimeException {
    traceIn(m.i, m.e);
    if (c.handling) {
      throw new RuntimeException("a valued event cannot be deferred");
    }
    c.handling = true;
    R r = f.action();
    c.handling = false;
    flush(c);
    traceOut(m.i, r.getClass().getSimpleName() + "_" + r.name());
    return r;
  };
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
// end header
