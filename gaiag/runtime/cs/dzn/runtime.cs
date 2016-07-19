// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

using System;
using System.Collections.Generic;
using System.Diagnostics;

namespace dzn {
    public class V<T> where T : new()
        {
            public T v;
            public V() { this.v = new T(); }
            public V(T v) { this.v = v; }
        }

        public class RuntimeException : SystemException {
        public RuntimeException(String msg) : base(msg) {}
    }

    abstract public class ComponentBase {
        public Locator dzn_locator;
        public Runtime dzn_runtime;
        public Meta dzn_meta;
        public ComponentBase(Locator locator, String name, Meta parent) {this.dzn_locator = locator; this.dzn_meta = new Meta (name, parent); this.dzn_runtime = locator.get<Runtime>(); this.dzn_runtime.components.Enqueue(this);}
    }

    public class Component : ComponentBase {
        public bool dzn_handling;
        public bool dzn_flushes;
        public Component dzn_deferred;
        public Queue<Action> dzn_q;
        public Component(Locator locator, String name="", Meta parent=null)
            : base(locator, name, parent)
            {this.dzn_q = new Queue<Action>();}
    }

    abstract public class SystemComponent : ComponentBase {
        public SystemComponent(Locator locator, String name, Meta parent)
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
            return !c.dzn_runtime.components.Contains(c);
        }
        public static void flush(Component c) {
            if (!external(c)) {
                while (c.dzn_q.Count > 0) {
                    handle(c, c.dzn_q.Dequeue());
                }
                if (c.dzn_deferred != null) {
                    Component t = c.dzn_deferred;
                    c.dzn_deferred = null;
                    if (!t.dzn_handling) {
                        flush(t);
                    }
                }
            }
        }
        public static void defer(Component i, Component o, Action f) {
            if (!(i !=null && i.dzn_flushes) && !o.dzn_handling) {
                handle(o, f);
            }
            else {
                o.dzn_q.Enqueue(f);
                if (i != null) {
                    i.dzn_deferred = o;
                }
            }
        }
        public static R valued_helper<R>(Component c, Func<R> f) where R : struct, IComparable, IConvertible {
            if (c.dzn_handling) {
                throw new RuntimeException("a valued event cannot be deferred");
            }
            c.dzn_handling = true;
            R r = f();
            c.dzn_handling = false;
            flush(c);
            return r;
        }
        public static void handle(Component c, Action f) {
            if (!c.dzn_handling) {
                c.dzn_handling = true;
                f();
                c.dzn_handling = false;
                flush(c);
            }
            else {
                throw new RuntimeException("component already handling an event");
            }
        }
        public static void callIn(Component c, Action f, port.Meta m, String e) {
            traceIn(m, e);
            handle(c, f);
            traceOut(m, "return");
        }
        public static R callIn<R>(Component c, Func<R> f, port.Meta m, String e) where R : struct, IComparable, IConvertible {
            traceIn(m, e);
            R r = valued_helper(c, f);
            String s;
            if (r.GetType().Equals(typeof(bool)))
                s = (bool)Convert.ChangeType(r,typeof(bool)) ? "true" : "false";
            else if (r.GetType().Equals(typeof(int)))
                s = r.ToString();
            else
                s = r.GetType().Name + "_" + Enum.GetName(r.GetType(),r);
            traceOut(m, s);
            return r;
        }
        public static void callOut(Component c, Action f, port.Meta m, String e) {
            traceOut(m, e);
            defer(m.provides.component, c, f);
        }
        public static String path(Meta m, String p="") {
            p = p == "" ? p : "." + p;
            if (m == null) return "<external>" + p;
            if (m.parent == null) return m.name + p;
            return path(m.parent, m.name + p);
        }
        public static void traceIn(port.Meta m, String e) {
            System.Console.Error.WriteLine(path(m.requires.meta, m.requires.name) + "." + e + " -> "
                                           + path(m.provides.meta, m.provides.name) + "." + e);
        }
        public static void traceOut(port.Meta m, String e) {
            System.Console.Error.WriteLine(path(m.provides.meta, m.provides.name) + "." + e + " -> "
                                           + path(m.requires.meta, m.requires.name) + "." + e);
        }
    }
}
