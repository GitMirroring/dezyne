// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2017, 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
// Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Threading;

namespace dzn
{
  public class container<TSystem> : Component, IDisposable where TSystem : Component
  {
    public bool flush;
    public TSystem system;
    public Dictionary<String, Action> lookup;
    public Queue<String> trail;
    public pump pump;
    public Component nullptr;

    public container(Func<Locator,String,TSystem> new_system, bool flush, Locator locator)
    : base(locator, "<external>", null)
    {
      this.flush = flush;
      this.pump = new pump();
      this.nullptr = new Component(locator);
      trail = new Queue<String>();
      system = new_system(locator.set(this.pump),"sut");
      system.dzn_runtime.states[this].flushes = flush;
    }
    public container(Func<Locator,String,TSystem> new_system, bool flush)
    : this (new_system, flush, new Locator().set(new dzn.Runtime(() => {
                    System.Console.Error.WriteLine("illegal");
                    Environment.Exit(0);})))
    {}
    ~container()
    {
      Dispose(false);
    }
    protected virtual void Dispose(bool gc)
    {
      if (gc)
      {
        pump p = system.dzn_locator.get<pump>();
        if(p != null && p != this.pump) this.pump.execute(() => {p.Dispose();});
        this.pump.Dispose();
      }
    }
    public void Dispose()
    {
      Debug.WriteLine("container.Dispose");
      context.lck(this, () => {
        while (this.trail.Count != 0)
          Monitor.Wait(this);
        pump p = system.dzn_locator.get<pump>();
        if (p != null && p != pump)
          pump.execute (()=>{p.stop();});
        pump.wait();
      });
      Dispose(true);
      GC.SuppressFinalize(this);
    }
    public void perform(String str)
    {
      if (str.Count(c => (c == '.')) > 1
          || str == "<defer>")
        return;

      Action e = lookup.ContainsKey(str) ? this.lookup[str] : null;
      if (e != null)
        this.pump.execute(e);

      context.lck(this, () => {
        this.trail.Enqueue(str);
        Monitor.Pulse(this);
      });
    }
    public void run(Dictionary<String, Action> lookup)
    {
      this.lookup = lookup;
      pump.pause();
      String str;

      while ((str = System.Console.ReadLine()) != null)
      {
        if (str.IndexOf("<flush>") != -1
           || str == "<defer>")
          pump.flush();
        perform(str);
      }
      pump.resume();
    }
    public void match(String perform)
    {
      String expect = trail_expect();
      if(expect != perform)
        throw new runtime_error("unmatched expectation: trail expects: \"" + expect
                               + "\" behavior expects: \"" + perform + "\"");
    }
    public String trail_expect()
    {
      return context.lck(this, () => {
        while (this.trail.Count == 0)
          Monitor.Wait(this);
        var expect = this.trail.Dequeue();
        if (this.trail.Count == 0)
          Monitor.Pulse(this);
        return expect;
      });
    }
    public static R string_to_value<R>(String s) where R: struct, IComparable, IConvertible {
      String v = s.Substring(s.IndexOf(".")+1);
      if (typeof(R) == typeof(bool)) return (R)Convert.ChangeType(v,typeof(R));
      if (typeof(R) == typeof(int)) return (R)Convert.ChangeType(v,typeof(R));
      foreach (R e in Enum.GetValues(typeof(R))) {
        if ((typeof(R).Name + ":" + e.ToString()).Equals(s)) {
          return e;
        }
      }
      throw new System.ArgumentException("No such value: ", s);
    }
    public String to_string<R>(R r) where R: struct, IComparable, IConvertible {
      if(typeof(R) == typeof(int)) return r.ToString();
      if(typeof(R) == typeof(bool)) return (bool)Convert.ChangeType(r,typeof(bool)) ? "true" : "false";
      return r.GetType().Name + ":" + r.ToString();
    }
  }
}
