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
  public static void Main (String[] args)
  {
    // Debug.Listeners.Add (new TextWriterTraceListener (Console.Error));
    // Debug.AutoFlush = true;

    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    locator.set (runtime);
    using (blocking_system_diamond sut = new blocking_system_diamond (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.r_left.dzn_meta.provides.name = "r_left";
      sut.r_left.dzn_meta.provides.port = sut.r_left;
      sut.r_right.dzn_meta.provides.name = "r_right";
      sut.r_right.dzn_meta.provides.port = sut.r_right;

      sut.r_left.inport.hello = () =>
      {
        dzn.Runtime.traceIn (sut.r_left.dzn_meta, "hello");
        dzn.Runtime.traceOut (sut.r_left.dzn_meta, "return");
      };
      sut.r_right.inport.hello = () =>
      {
        dzn.Runtime.traceIn (sut.r_right.dzn_meta, "hello");
        dzn.Runtime.traceOut (sut.r_right.dzn_meta, "return");
      };

      // 1: run through left to bottom and block
      System.Threading.Thread f = new System.Threading.Thread ( () =>
      {
         sut.p.inport.hello ();
      });
      f.Start ();
      System.Threading.Thread.Sleep (100);

      // 2: release: finish left,
      //    continue through right to bottom and block
      sut.r_left.outport.world ();

      // 3: release: finish right and return
      sut.r_right.outport.world ();

      f.Join ();
    }
  }
}
