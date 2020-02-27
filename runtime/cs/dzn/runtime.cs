// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2017, 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
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

namespace dzn
{
    public class RuntimeException : SystemException
    {
        public RuntimeException(String msg) : base(msg) { }
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
                this.dzn_runtime.infos.Add(this, new Runtime.info());
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

        public class info
        {
            public bool handling;
            public Component deferred;
            public Queue<Action> q;
            public bool flushes;
            public info() { this.q = new Queue<Action>(); }
        }

        public Dictionary<Object, info> infos;
        public Action illegal;
        public Runtime(Action illegal = null)
        {
            if (illegal == null)
                {
                    illegal = () => { throw new RuntimeException("illegal"); };
                }
            this.illegal = illegal;
            this.infos = new Dictionary<Object, info>();
        }
        public bool external(Object c)
        {
            return !infos.ContainsKey(c);
        }
        public void flush(Object c)
        {
            if (!external(c))
                {
                    while (infos[c].q.Count > 0)
                        {
                            handle(c, infos[c].q.Dequeue());
                        }
                    if (infos[c].deferred != null)
                        {
                            Component t = infos[c].deferred;
                            infos[c].deferred = null;
                            if (!infos[t].handling)
                                {
                                    flush(t);
                                }
                        }
                }
        }
        public Queue<Action> queue(Object o)
        {
            if(!infos.ContainsKey(o)) infos.Add(o, new Runtime.info());
            return infos[o].q;
        }
        public void defer(Component i, Component o, Action f)
        {
            if (!(i != null && infos[i].flushes) && !infos[o].handling)
                {
                    handle(o, f);
                }
            else
                {
                    infos[o].q.Enqueue(f);
                    if (i != null)
                        {
                            infos[i].deferred = o;
                        }
                }
        }
        public R valued_helper<R>(Component c, Func<R> f) where R : struct, IComparable, IConvertible
        {
            if (infos[c].handling) throw new RuntimeException("a valued event cannot be deferred");

            infos[c].handling = true;
            R r = f();
            infos[c].handling = false;
            flush(c);
            return r;
        }
        public void handle(Object c, Action f)
        {
            if (!infos[c].handling)
                {
                    infos[c].handling = true;
                    f();
                    infos[c].handling = false;
                    flush(c);
                }
            else
                {
                    throw new RuntimeException("component already handling an event");
                }
        }
        public void call_in(Component c, Action f, port.Meta m, String e)
        {
            traceIn(m, e);
            handle(c, f);
            traceOut(m, "return");
        }
        public R call_in<R>(Component c, Func<R> f, port.Meta m, String e) where R : struct, IComparable, IConvertible
        {
            traceIn(m, e);
            R r = valued_helper(c, f);
            String s;
            if (r.GetType().Equals(typeof(bool)))
                s = (bool)Convert.ChangeType(r, typeof(bool)) ? "true" : "false";
            else if (r.GetType().Equals(typeof(int)))
                s = r.ToString();
            else
                s = r.GetType().Name + "_" + Enum.GetName(r.GetType(), r);
            traceOut(m, s);
            return r;
        }
        public void call_out(Component c, Action f, port.Meta m, String e)
        {
            traceOut(m, e);
            defer(m.provides.component, c, f);
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
            System.Console.Error.WriteLine(path(m.provides.meta, m.provides.name) + "." + e + " -> "
                                           + path(m.requires.meta, m.requires.name) + "." + e);
        }
    }
}
