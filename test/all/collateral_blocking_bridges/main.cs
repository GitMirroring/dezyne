// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger van Beusekom <rutger@dezyne.org>
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
//
// Commentary:
//
// Code:

using System;
using System.Collections.Generic;
using System.Diagnostics;

class main
{
  public static string read ()
  {
    string str = string.Empty;
    string line;
    while((line = System.Console.ReadLine()) != null)
    {
      str += (string.IsNullOrEmpty(str) ? "" : "\n") + line;
    }
    return str;
  }

  public static void Main(String[] args)
  {
    // Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
    // Debug.AutoFlush = true;

    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    locator.set (runtime);
    using(collateral_blocking_bridges sut = new collateral_blocking_bridges (locator))
    {
      sut.dzn_meta.name = "sut";

      sut.top_w.meta.provide.name = "top_w";
      sut.top_w.meta.provide.port = sut.top_w;

      sut.middle_w.meta.provide.name = "middle_w";
      sut.middle_w.meta.provide.port = sut.middle_w;

      sut.bottom_w.meta.provide.name = "bottom_w";
      sut.bottom_w.meta.provide.port = sut.bottom_w;

      sut.top_w.in_port.hello = () =>
      {
        dzn.Runtime.trace(sut.top_w.meta, "hello");
        dzn.Runtime.trace_out(sut.top_w.meta, "return");
      };
      sut.middle_w.in_port.hello = () =>
      {
        dzn.Runtime.trace(sut.middle_w.meta, "hello");
        dzn.Runtime.trace_out(sut.middle_w.meta, "return");
      };
      sut.bottom_w.in_port.hello = () =>
      {
        dzn.Runtime.trace(sut.bottom_w.meta, "hello");
        dzn.Runtime.trace_out(sut.bottom_w.meta, "return");
      };

      System.Threading.Thread f = new System.Threading.Thread (() => // 1: run through top to middle and block
      {
         sut.h.in_port.hello ();
      });
      f.Start ();

      System.Threading.Thread.Sleep(100);

      string trace = read ();
      if (false);
      // trace
      else if (trace == "h.hello\ntop_w.hello\ntop_w.return\nmiddle_w.hello\nmiddle_w.return\ntop_w.world\nmiddle_w.world\nbottom_w.hello\nbottom_w.return\nbottom_w.world\nh.return")
      {
        sut.top_w.out_port.world();    // 2: collaterally blocks on top
        sut.middle_w.out_port.world(); // 3: releases 1; 1 continues and blocks on bottom
        sut.bottom_w.out_port.world(); // 4: releases 1 again then 2 finishes
      }
      // trace.1
      else if (trace == "h.hello\ntop_w.hello\ntop_w.return\nmiddle_w.hello\nmiddle_w.return\nmiddle_w.world\nbottom_w.hello\nbottom_w.return\ntop_w.world\nbottom_w.world\nh.return")
      {
        sut.middle_w.out_port.world(); // 2: releases 1; 1 continues and blocks on bottom
        sut.top_w.out_port.world();    // 3: collaterally blocks on top
        sut.bottom_w.out_port.world(); // 4: releases 1 again then 2 finishes
      }
      // trace.2
      else if (trace == "h.hello\ntop_w.hello\ntop_w.return\nmiddle_w.hello\nmiddle_w.return\nmiddle_w.world\nbottom_w.hello\nbottom_w.return\nbottom_w.world\ntop_w.world\nh.return")
      {
        sut.middle_w.out_port.world(); // 2: releases 1; 1 continues and blocks on bottom
        sut.bottom_w.out_port.world(); // 3: releases 1 again then 2 finishes
        sut.top_w.out_port.world();    // 2: releases 1, finishes
        // 1 finished
      }
      else
        throw (new dzn.runtime_error ("missing trace"));

      f.Join ();
    }
  }
}
