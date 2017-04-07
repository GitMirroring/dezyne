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
using System.Threading;

class main {

  static void connect_ports (dzn.container<shell> c)
  {
    c.system.p_outer.outport.foo = (int i) => {
      dzn.Runtime.traceIn(c.system.p_outer.dzn_meta, "foo");
      c.match("p_outer.foo");
    };
    c.system.r_outer.inport.return_to_sender = (int i, dzn.V<int> j) => {
      dzn.Runtime.traceIn(c.system.r_outer.dzn_meta, "return_to_sender");
      c.match("r_outer.return_to_sender"); String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r_outer.dzn_meta, tmp.Split('.')[1]);
      return dzn.container<shell>.string_to_value<bool>(tmp.Split('.')[1]);
    };
  }

  static Dictionary<String, Action> event_map (dzn.container<shell> c)
  {
    c.system.p_outer.dzn_meta.requires.name = "p_outer";

    c.system.r_outer.dzn_meta.provides.component = c;
    c.system.r_outer.dzn_meta.provides.meta = c.dzn_meta;
    c.system.r_outer.dzn_meta.provides.name = "r_outer";



    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("p_outer.return_to_sender",()=>{new Thread(()=>{dzn.V<int> _1 = new dzn.V<int>(1); c.match("p_outer." + c.to_string<bool>(c.system.p_outer.inport.return_to_sender(0,_1))); }).Start();});
    lookup.Add("r_outer.foo",             ()=>{c.system.r_outer.outport.foo(0);});
    lookup.Add("r_outer.<flush>",         ()=>{Console.Error.WriteLine("r_outer.<flush>"); dzn.Runtime.flush(c.system);});
    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }

    using(dzn.container<shell> c = new dzn.container<shell>((loc,name)=>{return new shell(loc,name);}, Array.Exists(args, s => s == "--flush"))) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {"r_outer"});
    }
  }
}
