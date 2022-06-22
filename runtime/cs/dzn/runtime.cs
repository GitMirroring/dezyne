// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2017, 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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
            public int blocked;
            public Component deferred;
            public Queue<Action> q;
            public bool flushes;
            public State()
            {
                this.handling = 0;
                this.blocked = 0;
                this.q = new Queue<Action>();
                this.flushes = false;
            }
        }

        public Dictionary<Object, State> states;
        public Action illegal;

        public Runtime(Action illegal = null)
        {
            if (illegal == null)
            {
               illegal = () => { throw new RuntimeException("illegal"); };
            }
            this.illegal = illegal;
            this.states = new Dictionary<Object, State>();
        }
        public bool external(Object c)
        {
            return !states.ContainsKey(c);
        }
        public void flush(ComponentBase c)
        {
          flush(c, coroutine_id(c.dzn_locator));
        }
        public void flush(Object c, int coroutine_id)
        {
            states[c].handling = 0;
            if (!external(c))
                {
                    while (states[c].q.Count > 0)
                        {
                            handle(c, states[c].q.Dequeue(), coroutine_id);
                            states[c].handling = 0;
                        }
                    if (states[c].deferred != null)
                        {
                            Component t = states[c].deferred;
                            states[c].deferred = null;
                            if (states[t].handling == 0)
                                {
                                    flush(t, coroutine_id);
                                }
                        }
                }
        }
        public Queue<Action> queue(Object o)
        {
            if(!states.ContainsKey(o)) states.Add(o, new Runtime.State());
            return states[o].q;
        }
        public void defer(Component src, Component tgt, Action f, int coroutine_id)
        {
            if (!(src != null && states[src].flushes) && states[tgt].handling == 0)
                {
                    handle(tgt, f, coroutine_id);
                    flush(tgt, coroutine_id);
                }
            else
                {
                    states[tgt].q.Enqueue(f);
                    if (src != null)
                        {
                            states[src].deferred = tgt;
                        }
                }
        }
        public R valued_helper<R>(Component c, Func<R> f, int coroutine_id) where R : struct, IComparable, IConvertible
        {
            if (states[c].handling != 0) throw new RuntimeException("a valued event cannot be deferred");
            states[c].handling = coroutine_id;
            return f();
        }
        public void handle(Object c, Action f, int coroutine_id)
        {
            if (states[c].handling != 0) throw new RuntimeException("a valued event cannot be deferred");
            states[c].handling = coroutine_id;
            f();
        }
        public void call_in(Component c, Action f, Port p, String e)
        {
            if(states[c].handling != 0 || dzn.pump.port_blocked_p(c.dzn_locator, p))
            {
              dzn.pump.collateral_block(c, c.dzn_locator);
            }
            dzn.port.Meta m = (dzn.port.Meta) p.GetType().GetField("dzn_meta").GetValue(p);
            traceIn(m, e);
            handle(c, f, coroutine_id(c.dzn_locator));
            traceOut(m, "return");
            states[c].handling = 0;
        }
        public R call_in<R>(Component c, Func<R> f, Port p, String e) where R : struct, IComparable, IConvertible
        {
            if(states[c].handling != 0 || dzn.pump.port_blocked_p(c.dzn_locator, p))
            {
              dzn.pump.collateral_block(c, c.dzn_locator);
            }
            dzn.port.Meta m = (dzn.port.Meta) p.GetType().GetField("dzn_meta").GetValue(p);
            traceIn(m, e);
            R r = valued_helper(c, f, coroutine_id(c.dzn_locator));
            String s;
            if (r.GetType().Equals(typeof(bool)))
                s = (bool)Convert.ChangeType(r, typeof(bool)) ? "true" : "false";
            else if (r.GetType().Equals(typeof(int)))
                s = r.ToString();
            else
                s = r.GetType().Name + ":" + Enum.GetName(r.GetType(), r);
            traceOut(m, s);
            states[c].handling = 0;
            return r;
        }
        public void call_out(Component c, Action f, Port p, String e)
        {
            dzn.port.Meta m = (dzn.port.Meta) p.GetType().GetField("dzn_meta").GetValue(p);
            if(!(p is async_base))
              traceQin(m, e);
            defer(m.provides.component, c, () => {
              if(!(p is async_base))
                traceQout(m, e);
              f();
            }, coroutine_id(c.dzn_locator));
        }
        public static int coroutine_id(dzn.Locator l)
        {
          dzn.pump p = l.try_get<dzn.pump>();
          return p == null ? 1 : p.coroutine_id();
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
