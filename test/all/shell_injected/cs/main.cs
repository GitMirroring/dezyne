// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

class main {

  static void connect_ports (dzn.container<shell_injected> c)
  {
    c.system.r.inport.e = () => {
      dzn.Runtime.traceIn(c.system.r.dzn_meta, "e");
      c.match("r.e");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r.dzn_meta, tmp.Split('.')[1]);
      return ;
    };c.system.p.outport.f = () => {
      c.match("p.f");
      c.dzn_runtime.call_out(c, () => {
        if(c.flush) c.dzn_runtime.queue(c).Enqueue(() => {
          if(c.dzn_runtime.queue(c).Count == 0) {
            Console.Error.WriteLine("p.<flush>");
            c.match("p.<flush>");
          }
        });
      }, c.system.p, "f");
    };
  }

  static Dictionary<String, Action> event_map (dzn.container<shell_injected> c)
  {
    c.system.p.dzn_meta.requires.component = c;
    c.system.p.dzn_meta.requires.meta = c.dzn_meta;
    c.system.p.dzn_meta.requires.name = "p";
    c.system.r.dzn_meta.provides.component = c;
    c.system.r.dzn_meta.provides.meta = c.dzn_meta;
    c.system.r.dzn_meta.provides.name = "r";

    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("illegal",()=>{Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    lookup.Add("p.e",()=>{c.system.p.inport.e(); c.match("p.return");});
    lookup.Add("r.f",()=>{Thread.Sleep(1000); c.system.r.outport.f(); });
    lookup.Add("r.<flush>",()=>{System.Console.Error.WriteLine("r.<flush>");
      c.dzn_runtime.flush(c);
    });

    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }
    bool flush = Array.Exists(args, s => s == "--flush");
    using(dzn.container<shell_injected> c = new dzn.container<shell_injected>((loc,name)=>{return new shell_injected(loc,name);}, flush)) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {"r"});
    }
  }
}
