// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
    c.system.r.inport.hello_void = () => {
      dzn.Runtime.traceIn(c.system.r.dzn_meta, "hello_void");
      c.match("r.hello_void");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r.dzn_meta, tmp.Split('.')[1]);
      return ;
    };
    c.system.r.inport.hello_int = () => {
      dzn.Runtime.traceIn(c.system.r.dzn_meta, "hello_int");
      c.match("r.hello_int");
      String tmp = c.match_return();
      System.Console.WriteLine("hiero:" + tmp);
      dzn.Runtime.traceOut(c.system.r.dzn_meta, tmp.Split('.')[1]);
      return dzn.container<blocking_shell>.string_to_value<int>(tmp.Split('.')[1]);;
    };
    c.system.r.inport.hello_bool = () => {
      dzn.Runtime.traceIn(c.system.r.dzn_meta, "hello_bool");
      c.match("r.hello_bool");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r.dzn_meta, tmp.Split('.')[1]);
      return dzn.container<blocking_shell>.string_to_value<bool>(tmp.Split('.')[1]);;
    };
    c.system.r.inport.hello_enum = ( int i, out int j) => {
      dzn.Runtime.traceIn(c.system.r.dzn_meta, "hello_enum");
      c.match("r.hello_enum");
      String tmp = c.match_return();
      dzn.Runtime.traceOut(c.system.r.dzn_meta, tmp.Split('.')[1]);
      j = default(int);
      return dzn.container<blocking_shell>.string_to_value<global::Enum>(tmp.Split('.')[1]);;
    };c.system.p.outport.world = ( int i) => {
      c.match("p.world");
      c.dzn_runtime.call_out(c, () => {
        if(c.flush) c.dzn_runtime.queue(c).Enqueue(() => {
          if(c.dzn_runtime.queue(c).Count == 0) {
            Console.Error.WriteLine("p.<flush>");
            c.match("p.<flush>");
          }
        });
      }, c.system.p, "world");
    };
  }

  static Dictionary<String, Action> event_map (dzn.container<blocking_shell> c)
  {
    c.system.p.dzn_meta.requires.component = c;
    c.system.p.dzn_meta.requires.meta = c.dzn_meta;
    c.system.p.dzn_meta.requires.name = "p";
    c.system.r.dzn_meta.provides.component = c;
    c.system.r.dzn_meta.provides.meta = c.dzn_meta;
    c.system.r.dzn_meta.provides.name = "r";

    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("illegal",()=>{Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    lookup.Add("p.hello_void",()=>{c.system.p.inport.hello_void(); c.match("p.return");});
    lookup.Add("r.world",()=>{Thread.Sleep(1000); int i = default(int); c.system.r.outport.world( i); });
    lookup.Add("p.hello_int",()=>{c.match("p." + c.to_string<int>(c.system.p.inport.hello_int()));});
    lookup.Add("p.hello_bool",()=>{c.match("p." + c.to_string<bool>(c.system.p.inport.hello_bool()));});
    lookup.Add("p.hello_enum",()=>{int i = default(int); int j = default(int); c.match("p." + c.to_string<global::Enum>(c.system.p.inport.hello_enum( i, out j)));});
    lookup.Add("r.<flush>",()=>{System.Console.Error.WriteLine("r.<flush>"); c.dzn_runtime.flush(c);});

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
      c.run(event_map (c), new List<String> {"r"});
    }
  }
}
