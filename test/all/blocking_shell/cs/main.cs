// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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
using System.Threading.Tasks;

class main
{

  static bool is_reply (String s)
  {
    if (s == "") return false;
    string v = s.Substring (s.IndexOf ('.')+1);
    int x;
    return s.IndexOf (':') != -1
      || v == "return" || v == "true" || v == "false"
      || int.TryParse (v, out x);
  }

  public static List<String> read ()
  {
    List<String> trace = new List<String> ();
    String line;
    while ((line = System.Console.ReadLine ()) != null)
      trace.Add (line);
    return trace;
  }

  public static void Main (String[] args)
  {
    if (Array.Exists (args, s => s == "--debug"))
    {
      Debug.Listeners.Add (new TextWriterTraceListener (Console.Error));
      Debug.AutoFlush = true;
    }
    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    using(blocking_shell sut = new blocking_shell (locator.set (runtime)))
    {
      sut.dzn_meta.name = "sut";
      sut.p.meta.require.name = "p";
      sut.r.meta.provide.name = "r";

      int output = 0;

      Dictionary<String, Action> provides = new Dictionary<String, Action> ();
      provides.Add ("p.hello_void", ()=>{sut.p.in_port.hello_void ();});
      provides.Add ("p.hello_bool", ()=>{sut.p.in_port.hello_bool ();});
      provides.Add ("p.hello_int", ()=>{sut.p.in_port.hello_int ();});
      provides.Add ("p.hello_enum", ()=>{sut.p.in_port.hello_enum (123, out output);});

      Dictionary<String, Action> requires = new Dictionary<String, Action> ();
      requires.Add ("r.world", ()=>{sut.r.out_port.world (0);});

      int index = 0;
      List<String> trace = read ();

      sut.p.out_port.world = (int i) => {
        Debug.Assert (trace[index] == "p.world");
        ++index;
        dzn.Runtime.trace_qin (sut.p.meta, "world");
      };

      sut.r.in_port.hello_void = () => {
        dzn.context.lck (sut, () => {
          Debug.Assert (trace[index] == "r.hello_void");
          ++index;
          dzn.Runtime.trace (sut.r.meta, "hello_void");
          String tmp = trace[index];
          ++index;
          dzn.Runtime.trace_out (sut.r.meta, tmp.Split ('.')[1]);
        });
      };
      sut.r.in_port.hello_bool = () => {
        String tmp = default (String);
        dzn.context.lck (sut, () => {
          Debug.Assert (trace[index] == "r.hello_bool");
          ++index;
          dzn.Runtime.trace (sut.r.meta, "hello_bool");
          tmp = trace[index];
          dzn.Runtime.trace_out (sut.r.meta, tmp.Split ('.')[1]);
          ++index;
        });
        return dzn.container<blocking_shell>.string_to_value<bool> (tmp.Split ('.')[1]);
      };
      sut.r.in_port.hello_int  = () => {
        String tmp = default (String);
        dzn.context.lck (sut, () => {
          Debug.Assert (trace[index] == "r.hello_int");
          ++index;
          dzn.Runtime.trace (sut.r.meta, "hello_int");
          tmp = trace[index];
          dzn.Runtime.trace_out (sut.r.meta, tmp.Split ('.')[1]);
          ++index;
        });
        return dzn.container<blocking_shell>.string_to_value<int> (tmp.Split ('.')[1]);
      };
      sut.r.in_port.hello_enum = (int i, out int j) => {
        String tmp = default (String);
        j = default (int);
        dzn.context.lck (sut, () => {
          Debug.Assert (trace[index] == "r.hello_enum");
          ++index;
          dzn.Runtime.trace (sut.r.meta, "hello_enum");
          tmp = trace[index];
          dzn.Runtime.trace_out (sut.r.meta, tmp.Split ('.')[1]);
          ++index;
        });
        return dzn.container<blocking_shell>.string_to_value<global::Enum> (tmp.Split ('.')[1]);
      };

      Queue<Task> sync = new Queue<Task> ();

      dzn.context.lck (sut, () => {
        while (index < trace.Count)
        {
          Action pit = provides.ContainsKey (trace[index])
          ? provides[trace[index]] : null;
          if (pit != null)
          {
            Task task = new Task (() => {
              pit ();
              dzn.context.lck (sut, () => {++index;});
            });
            sync.Enqueue (task);
            task.Start();
            ++index;
            Monitor.Exit (sut);
          }
          else
          {
            Action rit = requires.ContainsKey (trace[index])
            ? requires[trace[index]] : null;
            if (rit != null)
            {
              rit ();
              ++index;
            }
            Monitor.Exit (sut);
          }
          Monitor.Enter (sut);
        }
        while (sync.Count != 0)
        {
          sync.Peek ().Wait ();
          sync.Dequeue ();
        }
      });
    }
  }
}
