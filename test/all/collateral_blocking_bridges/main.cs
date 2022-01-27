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

      sut.top_w.dzn_meta.provides.name = "top_w";
      sut.top_w.dzn_meta.provides.port = sut.top_w;

      sut.middle_w.dzn_meta.provides.name = "middle_w";
      sut.middle_w.dzn_meta.provides.port = sut.middle_w;

      sut.bottom_w.dzn_meta.provides.name = "bottom_w";
      sut.bottom_w.dzn_meta.provides.port = sut.bottom_w;

      sut.top_w.inport.hello = () =>
      {
        dzn.Runtime.traceIn(sut.top_w.dzn_meta, "hello");
        dzn.Runtime.traceOut(sut.top_w.dzn_meta, "return");
      };
      sut.middle_w.inport.hello = () =>
      {
        dzn.Runtime.traceIn(sut.middle_w.dzn_meta, "hello");
        dzn.Runtime.traceOut(sut.middle_w.dzn_meta, "return");
      };
      sut.bottom_w.inport.hello = () =>
      {
        dzn.Runtime.traceIn(sut.bottom_w.dzn_meta, "hello");
        dzn.Runtime.traceOut(sut.bottom_w.dzn_meta, "return");
      };

      System.Threading.Thread f = new System.Threading.Thread (() => // 1: run through top to middle and block
      {
         sut.h.inport.hello ();
      });
      f.Start ();

      System.Threading.Thread.Sleep(100);

      sut.top_w.outport.world();    // 2: collaterally blocks on top
      sut.middle_w.outport.world(); // 3: releases 1; 1 continues and blocks on bottom
      sut.bottom_w.outport.world(); // 4: releases 1 again then 2 finishes

      System.Threading.Thread.Sleep(100);

      f.Join ();
    }
  }
}
