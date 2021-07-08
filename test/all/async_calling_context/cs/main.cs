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
