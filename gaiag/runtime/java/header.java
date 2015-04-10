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

import java.util.LinkedList;
import java.util.Queue;

abstract class Action {
  public abstract void action();
}

abstract class ValuedAction<R> {
  public abstract R action();
}

interface ActionQueue extends Queue<Action> {};
        
@SuppressWarnings("unchecked")
abstract class Interface<I extends Interface.In, O extends Interface.Out> {
  interface In {
  }
  interface Out {
  }

  protected In in;
  protected Out out;

  public I getIn() {
    return (I) in;
  }

  public void setIn(I in) {
    this.in = in;
  }

  public O getOut() {
    return (O) out;
  }

  public void setOut(O out) {
    this.out = out;
  }

  @SuppressWarnings("rawtypes")
    public static void connect(Interface provided, Interface required) {
    provided.setOut(required.getOut());
    required.setIn(provided.getIn());
  };
}

abstract class ComponentBase {
  public Runtime runtime;
  public SystemComponent parent;
  public String name;
  public ComponentBase(Runtime runtime, String name, SystemComponent parent) {this.runtime = runtime; this.parent = parent; this.name = name;};
};

abstract class Component extends ComponentBase {
  public boolean handling;
  public boolean flushes;
  public Component deferred;
  public Queue<Action> q;
  public Component(Runtime runtime, String name, SystemComponent parent) {super(runtime, name, parent); this.q = new LinkedList<Action>();};
};

abstract class SystemComponent extends ComponentBase {
  public SystemComponent(Runtime runtime, String name, SystemComponent parent) {super(runtime, name, parent);};
};

class Meta {
  public Interface i;
  public String e;
  public Meta(Interface i, String e) {this.i = i; this.e = e;};
};

class Runtime {
  public static void callIn(Component c, Action f, Meta m) {
    traceIn(m.i, m.e);
    f.action();
    traceOut(m.i, "return");
  };
  public static void callOut(Component c, Action f, Meta m) {
    f.action();
    traceOut(m.i, m.e);
  };
  public static void traceIn(Interface i, String e) {
    System.err.println("" + i + "." + e);
  }
  public static void traceOut(Interface i, String e) {
    System.err.println("" + i + "." + e);
  }
};

// end header
