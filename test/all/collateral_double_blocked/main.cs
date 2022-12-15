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
    while ((line = System.Console.ReadLine ()) != null)
    {
      str += (string.IsNullOrEmpty (str) ? "" : "\n") + line;
    }
    return str;
  }

  public static void Main (String[] args)
  {
    // Debug.Listeners.Add (new TextWriterTraceListener (Console.Error));
    // Debug.AutoFlush = true;

    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    locator.set (runtime);
    collateral_double_blocked sut
      = new collateral_double_blocked (locator, "sut");
    dzn.pump pump = new dzn.pump ();
    locator.set (pump);

    sut.left.meta.require.name = "left";
    sut.left.meta.require.port = sut.left;

    sut.middle.meta.require.name = "middle";
    sut.middle.meta.require.port = sut.middle;

    sut.right.meta.require.name = "right";
    sut.right.meta.require.port = sut.right;

    sut.r.meta.provide.name = "r";
    sut.r.meta.provide.port = sut.r;

    sut.r.in_port.hello = () =>
    {
      dzn.Runtime.trace (sut.r.meta, "hello");
      dzn.Runtime.trace_out (sut.r.meta, "return");
    };

    // Let's pick just one trace of the 8 traces...
    string trace = read ();
    if (false);
    // trace
    else if (trace == "left.hello\nr.hello\nr.return\nmiddle.hello\nleft.return\nr.world\nmiddle.return")
    {
      pump.execute (() => sut.left.in_port.hello ());
      pump.execute (() => sut.middle.in_port.hello ());
      pump.execute (() => sut.r.out_port.world ());
    }
    else if (trace == "middle.hello\nr.hello\nr.return\nleft.hello\nmiddle.return\nr.world\nleft.return")
    {
      pump.execute (() => sut.middle.in_port.hello ());
      pump.execute (() => sut.left.in_port.hello ());
      pump.execute (() => sut.r.out_port.world ());
    }
    else
      throw (new dzn.runtime_error ("missing trace"));

    System.Threading.Thread.Sleep (100);
    pump.Dispose ();
  }
}
