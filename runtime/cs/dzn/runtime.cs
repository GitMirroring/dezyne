// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2017, 2018, 2019, 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
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

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

namespace dzn
{
    public class RuntimeException : SystemException
    {
        public RuntimeException(String msg) : base(msg) { }
    }

    abstract public class Port
    {
        public dzn.port.Meta dzn_meta;
        public Port()
        {
            dzn_meta = new dzn.port.Meta ();
        }
        public Port other ()
        {
            return (this == this.dzn_meta.provides.port)
            ? this.dzn_meta.requires.port : this.dzn_meta.provides.port;
        }
    }

    abstract public class ComponentBase
    {
        public Locator dzn_locator;
        public Runtime dzn_runtime;
        public Meta dzn_meta;
        public ComponentBase(Locator locator, String name, Meta parent)
        {
            this.dzn_locator = locator; this.dzn_meta = new Meta(name, parent);
            this.dzn_runtime = locator.get<Runtime>();
        }
    }

    public class Component : ComponentBase
    {
        public Component(Locator locator, String name = "", Meta parent = null)
            : base(locator, name, parent)
            {
                this.dzn_runtime.states.Add(this, new Runtime.State());
            }
    }

    abstract public class SystemComponent : Component
    {
        public SystemComponent(Locator locator, String name, Meta parent)
            : base(locator, name, parent)
            { }
    }

    public static class RuntimeHelper
    {
        public static void apply(Meta m, Action<Meta> a)
        {
            a(m);
            foreach (var c in m.children) apply(c, a);
        }

        public static void check_bindings(Meta m)
        {
            apply(m, (Meta mm) => {foreach (var p in mm.ports_connected) p();});
        }
    }

    public class Runtime
    {

        public class State
        {
            public int handling;
            public Component deferred;
            public Queue<Action> q;
            public bool flushes;
            public State()
            {
                this.handling = 0;
                this.q = new Queue<Action>();
                this.flushes = false;
            }
        }

        public Dictionary<Object, State> states;
        public Stack<Object> component_stack;
        public Dictionary<int, Stack<Object>> blocked_port_component_stack;
        public Action illegal;

        public Runtime(Action illegal = null)
        {
            if (illegal == null)
            {
               illegal = () => { throw new RuntimeException("illegal"); };
            }
            this.illegal = illegal;
            this.states = new Dictionary<Object, State>();
            this.component_stack = new Stack<Object>();
            this.blocked_port_component_stack = new Dictionary<int, Stack<Object>>();
        }
        public bool external(Object c)
        {
            return !states.ContainsKey(c);
        }
        public void flush(Object c)
        {
            if (!external(c))
                {
                    while (states[c].q.Count > 0)
                        {
                            handle(c, states[c].q.Dequeue());
                        }
                    if (states[c].deferred != null)
                        {
                            Component t = states[c].deferred;
                            states[c].deferred = null;
                            if (states[t].handling == 0)
                                {
                                    flush(t);
                                }
                        }
                }
        }
        public Queue<Action> queue(Object o)
        {
            if(!states.ContainsKey(o)) states.Add(o, new Runtime.State());
            return states[o].q;
        }
        public void defer(Component i, Component o, Action f)
        {
            if (!(i != null && states[i].flushes) && states[o].handling == 0)
                {
                    handle(o, f);
                }
            else
                {
                    states[o].q.Enqueue(f);
                    if (i != null)
                        {
                            states[i].deferred = o;
                        }
                }
        }
        public R valued_helper<R>(Component c, Func<R> f) where R : struct, IComparable, IConvertible
        {
            if (states[c].handling != 0) throw new RuntimeException("a valued event cannot be deferred");
            int initial = states[c].handling;
            states[c].handling = coroutine.get_id();
            R r = f();
            states[c].handling = initial;
            flush(c);
            return r;
        }
        public void handle(Object c, Action f)
        {
            if (states[c].handling != 0) throw new RuntimeException("a valued event cannot be deferred");
            int initial = states[c].handling;
            states[c].handling = coroutine.get_id();
            f();
            states[c].handling = initial;
            flush(c);
        }
        public void call_in(Component c, Action f, Port p, String e)
        {
            if(states[c].handling != 0 || dzn.pump.port_blocked_p(c.dzn_locator, p))
            {
              dzn.pump.collateral_block(c, c.dzn_locator);
            }
            component_stack.Push(c);
            dzn.port.Meta m = (dzn.port.Meta) p.GetType().GetField("dzn_meta").GetValue(p);
            traceIn(m, e);
            handle(c, f);
            traceOut(m, "return");
            component_stack.Pop();
        }
        public R call_in<R>(Component c, Func<R> f, Port p, String e) where R : struct, IComparable, IConvertible
        {
            if(states[c].handling != 0 || dzn.pump.port_blocked_p(c.dzn_locator, p))
            {
              dzn.pump.collateral_block(c, c.dzn_locator);
            }
            component_stack.Push(c);
            dzn.port.Meta m = (dzn.port.Meta) p.GetType().GetField("dzn_meta").GetValue(p);
            traceIn(m, e);
            R r = valued_helper(c, f);
            String s;
            if (r.GetType().Equals(typeof(bool)))
                s = (bool)Convert.ChangeType(r, typeof(bool)) ? "true" : "false";
            else if (r.GetType().Equals(typeof(int)))
                s = r.ToString();
            else
                s = r.GetType().Name + ":" + Enum.GetName(r.GetType(), r);
            traceOut(m, s);
            component_stack.Pop();
            return r;
        }
        public void call_out(Component c, Action f, Port p, String e)
        {
            dzn.port.Meta m = (dzn.port.Meta) p.GetType().GetField("dzn_meta").GetValue(p);
            if(!(p is async_base))
              traceQin(m, e);
            defer(m.provides.component, c, () => {
              component_stack.Push(c);
              f();
              component_stack.Pop();
            });
        }
        public static String path(Meta m, String p = "")
        {
            p = p == "" ? p : "." + p;
            if (m == null) return "<external>" + p;
            if (m.parent == null)
                return (m.name != "" ? m.name : "<external>") + p;
            return path(m.parent, m.name + p);
        }
        public static void traceIn(port.Meta m, String e)
        {
            System.Console.Error.WriteLine(path(m.requires.meta, m.requires.name) + "." + e + " -> "
                                           + path(m.provides.meta, m.provides.name) + "." + e);
        }
        public static void traceOut(port.Meta m, String e)
        {
            System.Console.Error.WriteLine(path(m.requires.meta, m.requires.name) + "." + e + " <- "
                                           + path(m.provides.meta, m.provides.name) + "." + e);
        }
        public static void traceQin(port.Meta m, String e)
        {
            if(path(m.provides.meta) == "<external>")
                System.Console.Error.WriteLine(path(m.requires.meta, "<q>") + " <- " +
                                               path(m.provides.meta, m.provides.name) + "." + e);
            else
                System.Console.Error.WriteLine(path(m.provides.meta, m.provides.name) + ".<q> <- " +
                                               path(m.requires.meta, m.requires.name) + "." + e);

        }
        public static void traceQout(port.Meta m, String e)
        {
            System.Console.Error.WriteLine(path(m.requires.meta, m.requires.name) + "." + e + " <- " +
                                           path(m.requires.meta, "<q>"));
        }
    }
}
