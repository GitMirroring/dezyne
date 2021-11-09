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

  static void connect_ports (dzn.container<blocking_shell> c)
  {
    c.system.r_outer.inport.return_void = () => {
      dzn.Runtime.traceIn(c.system.r_outer.dzn_meta, "return_void");
      c.match("r_outer.return_void");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r_outer.dzn_meta, tmp.Split('.')[1]);
      return ;
    };
    c.system.r_outer.inport.return_int = () => {
      dzn.Runtime.traceIn(c.system.r_outer.dzn_meta, "return_int");
      c.match("r_outer.return_int");
      String tmp = c.match_return();
      System.Console.WriteLine("hiero:" + tmp);
      dzn.Runtime.traceOut(c.system.r_outer.dzn_meta, tmp.Split('.')[1]);
      return dzn.container<blocking_shell>.string_to_value<int>(tmp.Split('.')[1]);;
    };
    c.system.r_outer.inport.return_bool = () => {
      dzn.Runtime.traceIn(c.system.r_outer.dzn_meta, "return_bool");
      c.match("r_outer.return_bool");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r_outer.dzn_meta, tmp.Split('.')[1]);
      return dzn.container<blocking_shell>.string_to_value<bool>(tmp.Split('.')[1]);;
    };
    c.system.r_outer.inport.return_enum = ( int i, out int j) => {
      dzn.Runtime.traceIn(c.system.r_outer.dzn_meta, "return_enum");
      c.match("r_outer.return_enum");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r_outer.dzn_meta, tmp.Split('.')[1]);
      j = default(int);
      return dzn.container<blocking_shell>.string_to_value<global::Enum>(tmp.Split('.')[1]);;
    };c.system.p_outer.outport.foo = ( int i) => {
      c.match("p_outer.foo");
      c.dzn_runtime.call_out(c, () => {
        if(c.flush) c.dzn_runtime.queue(c).Enqueue(() => {
          if(c.dzn_runtime.queue(c).Count == 0) {
            Console.Error.WriteLine("p_outer.<flush>");
            c.match("p_outer.<flush>");
          }
        });
      }, c.system.p_outer, "foo");
    };
  }

  static Dictionary<String, Action> event_map (dzn.container<blocking_shell> c)
  {
    c.system.p_outer.dzn_meta.requires.component = c;
    c.system.p_outer.dzn_meta.requires.meta = c.dzn_meta;
    c.system.p_outer.dzn_meta.requires.name = "p_outer";
    c.system.r_outer.dzn_meta.provides.component = c;
    c.system.r_outer.dzn_meta.provides.meta = c.dzn_meta;
    c.system.r_outer.dzn_meta.provides.name = "r_outer";

    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("illegal",()=>{Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    lookup.Add("p_outer.return_void",()=>{c.system.p_outer.inport.return_void(); c.match("p_outer.return");});
    lookup.Add("r_outer.foo",()=>{Thread.Sleep(1000); int i = default(int); c.system.r_outer.outport.foo( i); });
    lookup.Add("p_outer.return_int",()=>{c.match("p_outer." + c.to_string<int>(c.system.p_outer.inport.return_int()));});
    lookup.Add("p_outer.return_bool",()=>{c.match("p_outer." + c.to_string<bool>(c.system.p_outer.inport.return_bool()));});
    lookup.Add("p_outer.return_enum",()=>{int i = default(int); int j = default(int); c.match("p_outer." + c.to_string<global::Enum>(c.system.p_outer.inport.return_enum( i, out j)));});
    lookup.Add("r_outer.<flush>",()=>{System.Console.Error.WriteLine("r_outer.<flush>"); c.dzn_runtime.flush(c);});

    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }
    bool flush = Array.Exists(args, s => s == "--flush");
    using(dzn.container<blocking_shell> c = new dzn.container<blocking_shell>((loc,name)=>{return new blocking_shell(loc,name);}, flush)) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {"r_outer"});
    }
  }
}

