// -*-java-*-
// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  static void connect_ports (dzn.container<async_shell> c)
  {
    c.system.h.outport.world = () => {
      Thread.Sleep(100);
      c.match("h.world");
      c.dzn_runtime.call_out(c, () => {
        if(c.flush) c.dzn_runtime.queue(c).Enqueue(() => {
          if(c.dzn_runtime.queue(c).Count == 0) {
            Console.Error.WriteLine("h.<flush>");
            c.match("h.<flush>");
          }
        });
      }, c.system.h, "world");
    };
  }

  static Dictionary<String, Action> event_map (dzn.container<async_shell> c)
  {
    c.system.h.dzn_meta.requires.component = c;
    c.system.h.dzn_meta.requires.meta = c.dzn_meta;
    c.system.h.dzn_meta.requires.name = "h";

    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("illegal",()=>{Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    lookup.Add("h.hello",()=>{c.system.h.inport.hello(); c.match("h.return");});

    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }
    bool flush = Array.Exists(args, s => s == "--flush");
    using(dzn.container<async_shell> c = new dzn.container<async_shell>((loc,name)=>{return new async_shell(loc,name);}, flush)) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {});
    }
  }
}
