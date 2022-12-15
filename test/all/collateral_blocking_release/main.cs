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
    collateral_blocking_release sut
      = new collateral_blocking_release (locator, "sut");
    dzn.pump pump = new dzn.pump ();
    locator.set (pump);

    sut.block.meta.require.name = "block";
    sut.block.meta.require.port = sut.block;

    sut.release.meta.require.name = "release";
    sut.release.meta.require.port = sut.release;

    sut.w.meta.provide.name = "w";
    sut.w.meta.provide.port = sut.w;

    sut.w.in_port.hello = () =>
    {
      dzn.Runtime.trace (sut.w.meta, "hello");
      dzn.Runtime.trace_out (sut.w.meta, "return");
    };

    string trace = read ();
    if (false);
    // trace
    else if (trace == "block.hello\nw.hello\nw.return\nrelease.hello\nw.hello\nw.return\nrelease.return\nrelease.hello\nrelease.return\nblock.return")
    {
      pump.execute (() => sut.block.in_port.hello ());
      pump.execute (() => {sut.release.in_port.hello (); sut.release.in_port.hello ();});
    }
    else if (trace == "block.hello\nw.hello\nw.return\nw.world\nblock.return")
    {
      pump.execute (() => sut.block.in_port.hello ());
      pump.execute (() => sut.release.in_port.hello ());
    }
    else if (trace == "block.hello\nw.hello\nw.return\nw.world\nblock.return")
    {
      pump.execute (() => sut.block.in_port.hello ());
      pump.execute (() => sut.w.out_port.world ());
    }
    else if (trace == "release.hello\nrelease.return")
      pump.execute (() => sut.release.in_port.hello ());
    else
      throw (new dzn.runtime_error ("missing trace"));

    pump.wait ();
    pump.Dispose ();
  }
}
