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
    collateral_double_blocked sut = new collateral_double_blocked (locator);
    dzn.pump pump = new dzn.pump ();
    locator.set (pump);

    sut.dzn_meta.name = "sut";

    sut.left.dzn_meta.requires.name = "left";
    sut.left.dzn_meta.requires.port = sut.left;

    sut.middle.dzn_meta.requires.name = "middle";
    sut.middle.dzn_meta.requires.port = sut.middle;

    sut.right.dzn_meta.requires.name = "right";
    sut.right.dzn_meta.requires.port = sut.right;

    sut.r.dzn_meta.provides.name = "r";
    sut.r.dzn_meta.provides.port = sut.r;

    sut.r.inport.hello = () =>
    {
      dzn.Runtime.traceIn (sut.r.dzn_meta, "hello");
      dzn.Runtime.traceOut (sut.r.dzn_meta, "return");
    };

    // Let's pick just one trace of the 8 traces...
    string trace = read ();
    if (false);
    // trace
    else if (trace == "left.hello\nr.hello\nr.return\nmiddle.hello\nleft.return\nr.world\nmiddle.return")
    {
      pump.execute (() => sut.left.inport.hello ());
      pump.execute (() => sut.middle.inport.hello ());
      pump.execute (() => sut.r.outport.world ());
    }
    else if (trace == "middle.hello\nr.hello\nr.return\nleft.hello\nmiddle.return\nr.world\nleft.return")
    {
      pump.execute (() => sut.middle.inport.hello ());
      pump.execute (() => sut.left.inport.hello ());
      pump.execute (() => sut.r.outport.world ());
    }
    else
      throw (new dzn.runtime_error ("missing trace"));

    System.Threading.Thread.Sleep (100);
    pump.Dispose ();
  }
}
