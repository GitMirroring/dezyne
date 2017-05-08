// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  static void connect_ports (dzn.container<SimpleBlockingBinding> c)
  {
    c.system.r.inport.e = () => {
      dzn.Runtime.traceIn(c.system.r.dzn_meta, "e"); //System.Console.Error.WriteLine("");
      c.match("r.e"); String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r.dzn_meta, tmp.Split('.')[1]); //System.Console.Error.WriteLine("");
      return;
    };
  }

  static Dictionary<String, Action> event_map (dzn.container<SimpleBlockingBinding> c)
  {
    c.system.p.dzn_meta.requires.name = "p";

    c.system.r.dzn_meta.provides.component = c;
    c.system.r.dzn_meta.provides.meta = c.dzn_meta;
    c.system.r.dzn_meta.provides.name = "r";



    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("p.e",()=>{dzn.V<int> _0 = new dzn.V<int>(0); c.system.p.inport.e(_0);
                          Debug.Assert(_0.v == 456);
                          c.match("p.return");});
    lookup.Add("r.cb",()=>{c.system.r.outport.cb();
    });
    lookup.Add("r.<flush>",()=>{System.Console.Error.WriteLine("r.<flush>"); dzn.Runtime.flush(c.system);});
    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }

    using(dzn.container<SimpleBlockingBinding> c = new dzn.container<SimpleBlockingBinding>((loc,name)=>{return new SimpleBlockingBinding(loc,name);}, Array.Exists(args, s => s == "--flush"))) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {"r"});
    }
  }
}
