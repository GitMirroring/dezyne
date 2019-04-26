// Dezyne --- Dezyne command line tools
//
// Copyright © 2017, 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
using System.Diagnostics;
using System.Collections.Generic;
using System.Reflection;
using System.Threading;

namespace dzn
{
  public class container<TSystem> : Component, IDisposable where TSystem : Component
  {
    public bool flush;
    public TSystem system;
    public Dictionary<String, Action> lookup;
    public Queue<String> expect;
    public pump pump;

    public container(Func<Locator,String,TSystem> new_system, bool flush, Locator locator)
    : base(locator, "<external>", null)
    {
      this.flush = flush;
      this.pump = new pump();
      this.expect = new Queue<String>();
      this.system = new_system(locator.set(this.pump),"sut");
      this.system.dzn_runtime.infos[this].flushes = flush;
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
      Dispose(true);
      GC.SuppressFinalize(this);
    }
    public String match_return()
    {
      return context.lck(this, () => {
          while (expect.Count == 0) Monitor.Wait(this);
          String tmp = this.expect.Dequeue();
          Action e = this.lookup.ContainsKey(tmp) ? this.lookup[tmp] : null;
          while(e != null)
          {
            e();
            while (this.expect.Count == 0) Monitor.Wait(this);
            tmp = this.expect.Dequeue();
            e = this.lookup.ContainsKey(tmp) ? this.lookup[tmp] : null;
          }
          if(this.expect.Count == 0) Monitor.Pulse(this);
          return tmp;
        });
    }
    public void match(String actual)
    {
      String tmp = match_return();
      if(actual != tmp)
        throw new runtime_error("unmatched expectation: behaviour expects: \"" + actual + "\" trace expects: \"" + tmp + "\"");
    }
    public void run(Dictionary<String, Action> lookup, List<String> required_ports)
    {
      this.lookup = lookup;
      String port = "";
      String str;

      while((str = System.Console.ReadLine()) != null)
      {
        Action e = this.lookup.ContainsKey(str) ? this.lookup[str] : null;
        if(e == null || port != "")
        {
          String p = str.Split('.')[0];
          if(e == null && required_ports.Find(o => {return o == p;}) != null)
          {
            if(port == "" || port != p) port = p;
            else port = "";
          }
          context.lck(this, () => {
              Monitor.Pulse(this);
              this.expect.Enqueue(str);
            });
        }
        else
        {
          pump.execute(e);
          port = "";
        }
      }
      context.lck(this, () => {while (expect.Count != 0) Monitor.Wait(this);});
    }
    public static R string_to_value<R>(String s) where R: struct, IComparable, IConvertible {
      String v = s.Substring(s.IndexOf(".")+1);
      if (typeof(R) == typeof(bool)) return (R)Convert.ChangeType(v,typeof(R));
      if (typeof(R) == typeof(int)) return (R)Convert.ChangeType(v,typeof(R));
      foreach (R e in Enum.GetValues(typeof(R))) {
        if ((typeof(R).Name + "_" + e.ToString()).Equals(s)) {
          return e;
        }
      }
      throw new System.ArgumentException("No such value: ", s);
    }
    public String to_string<R>(R r) where R: struct, IComparable, IConvertible {
      if(typeof(R) == typeof(int)) return r.ToString();
      if(typeof(R) == typeof(bool)) return (bool)Convert.ChangeType(r,typeof(bool)) ? "true" : "false";
      return r.GetType().Name + "_" + r.ToString();
    }
  }
}
