// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
// -*-java-*-
using System;
using System.Collections.Generic;
using System.Diagnostics;

class main {

  static calling_context dzn_cc = default( calling_context);
  static void connect_ports (dzn.container<async_calling_context> c)
  {
    c.system.p.outport.world = (ref  calling_context dzn_cc,  string s) => {
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

  static Dictionary<String, Action> event_map (dzn.container<async_calling_context> c)
  {
    c.system.p.dzn_meta.requires.component = c;
    c.system.p.dzn_meta.requires.meta = c.dzn_meta;
    c.system.p.dzn_meta.requires.name = "p";

    Dictionary<String, Action> lookup = new Dictionary<String, Action>();
    lookup.Add("illegal",()=>{Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    lookup.Add("p.hello",()=>{
      string s = default(string); c.system.p.inport.hello(ref dzn_cc,  s); c.match("p.return");});
    lookup.Add("p.bye",()=>{
            c.system.p.inport.bye(ref dzn_cc); c.match("p.return");});
    lookup.Add("a.ack",()=>{
      string s = default(string);
      c.system.a.outport.ack(ref dzn_cc,  s); });

    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }
    bool flush = Array.Exists(args, s => s == "--flush");
    using(dzn.container<async_calling_context> c = new dzn.container<async_calling_context>((loc,name)=>{return new async_calling_context(loc,name);}, flush)) {
      connect_ports (c);
      c.run(event_map (c), new List<String> {});
    }
  }
}
//version: 2.12.0.rc1.3-4fcb88
