// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

// -*-java-*-
using System;
using System.Collections.Generic;
using System.Diagnostics;

class main {

  static void connect_ports (dzn.container<calling_context> c)
  {
    c.system.w.inport.world = (ref int dzn_cc, int i) => {
      dzn.Runtime.traceIn(c.system.w.dzn_meta, "world");
      c.match("w.world");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.w.dzn_meta, tmp.Split('.')[1]);
      return ;
    };

  }

  static Dictionary<String, Action> event_map (dzn.container<calling_context> c)
  {
    c.system.h.dzn_meta.requires.name = "h";
    c.system.w.dzn_meta.provides.component = c;
    c.system.w.dzn_meta.provides.meta = c.dzn_meta;
    c.system.w.dzn_meta.provides.name = "w";


    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("h.hello",()=>{int _0 = 0; int _1 = 1;
                              c.system.h.inport.hello(ref _0, _1); c.match("h.return");});

    lookup.Add("w.<flush>",()=>{System.Console.Error.WriteLine("w.<flush>");
      c.system.dzn_runtime.flush(c.system);
      c.system.dzn_runtime.flush(c.system.h);

    });

    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }

    using(dzn.container<calling_context> c = new dzn.container<calling_context>((loc,name)=>{return new calling_context(loc,name);}, Array.Exists(args, s => s == "--flush"))) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {"w"});
    }
  }
}
//version: development
