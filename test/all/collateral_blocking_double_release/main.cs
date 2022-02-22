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
    //using (blocking_release sut = new blocking_release (locator))
    collateral_blocking_double_release sut = new collateral_blocking_double_release (locator);
    dzn.pump pump = new dzn.pump ();
    locator.set (pump);

    sut.dzn_meta.name = "sut";

    sut.block0.dzn_meta.requires.name = "block0";
    sut.block0.dzn_meta.requires.port = sut.block0;

    sut.block1.dzn_meta.requires.name = "block1";
    sut.block1.dzn_meta.requires.port = sut.block1;

    sut.release.dzn_meta.requires.name = "release";
    sut.release.dzn_meta.requires.port = sut.release;

    sut.w.dzn_meta.provides.name = "w";
    sut.w.dzn_meta.provides.port = sut.w;

    sut.w.inport.hello = () =>
    {
      dzn.Runtime.traceIn (sut.w.dzn_meta, "hello");
      dzn.Runtime.traceOut (sut.w.dzn_meta, "return");
    };

    sut.w.inport.cruel = () =>
    {
      dzn.Runtime.traceIn (sut.w.dzn_meta, "cruel");
      dzn.Runtime.traceOut (sut.w.dzn_meta, "return");
    };

    // Let's just pick one trace
    string trace = read ();
    if (false);
    else if (trace == "block1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.hello\nw.hello\nw.return\nblock1.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return")
    {
      pump.execute (() => {sut.block1.inport.hello (); sut.release.inport.hello ();});
      pump.execute (() => {sut.release.inport.hello (); sut.block0.inport.hello ();});
    }
    else if (trace == "block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nw.world\nw.cruel\nw.return\nblock0.return\nblock1.return")
    {
      pump.execute (() => sut.block0.inport.hello ());
      pump.execute (() => sut.block1.inport.hello ());
      pump.execute (() => sut.w.outport.world ());
    }
    else if (trace == "block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return\nblock1.return")
    {
      pump.execute (() => sut.block0.inport.hello ());
      pump.execute (() => sut.block1.inport.hello ());
      pump.execute (() => sut.release.inport.hello ());
    }
    else
      throw (new dzn.runtime_error ("missing trace"));

    pump.wait ();
    pump.Dispose ();
  }
}
