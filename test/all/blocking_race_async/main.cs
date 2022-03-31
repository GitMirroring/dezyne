// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger van Beusekom <rutger@dezyne.org>
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
    blocking_race_async sut = new blocking_race_async (locator);
    dzn.pump pump = new dzn.pump ();
    locator.set (pump);

    sut.dzn_meta.name = "sut";

    sut.pt.dzn_meta.requires.name = "pt";
    sut.pt.dzn_meta.requires.port = sut.pt;
    sut.rb.dzn_meta.provides.name = "rb";
    sut.rb.dzn_meta.provides.port = sut.rb;
    sut.rt.dzn_meta.provides.name = "rt";
    sut.rt.dzn_meta.provides.port = sut.rt;

    bool complete = true;

    sut.pt.outport.complete = () =>
    {
      dzn.Runtime.traceOut (sut.pt.dzn_meta, "complete");
    };
    sut.rb.inport.block = () =>
    {
      dzn.Runtime.traceIn (sut.rb.dzn_meta, "block");
      if(complete) sut.rt.outport.complete();
      dzn.Runtime.traceOut (sut.rb.dzn_meta, "return");
    };
    sut.rt.inport.request = () =>
    {
      dzn.Runtime.traceIn (sut.rt.dzn_meta, "request");
      dzn.Runtime.traceOut (sut.rt.dzn_meta, "return");
    };
    sut.rt.inport.cancel = () =>
    {
      dzn.Runtime.traceIn (sut.rt.dzn_meta, "cancel");
      dzn.Runtime.traceOut (sut.rt.dzn_meta, "return");
    };

    string trace = read ();
    if (false);
    // trace
    else if (trace == "pt.cancel\nrt.cancel\nrt.return\npt.return")
    {
      pump.execute(() => sut.pt.inport.cancel());
    }
    else if (trace == "pt.request\nrt.request\nrt.return\nrb.block\nrt.complete\nrb.return\nrt.cancel\nrt.return\npt.return\npt.cancel\nrt.cancel\nrt.return\npt.return")
    {
      pump.execute(() => {sut.pt.inport.request(); sut.pt.inport.cancel();});
    }
    else if (trace == "pt.request\nrt.request\nrt.return\nrb.block\nrt.complete\nrb.return\nrt.cancel\nrt.return\npt.return\npt.complete")
    {
      pump.execute(() => sut.pt.inport.request());
    }
    else if (trace == "pt.request\nrt.request\nrt.return\nrb.block\nrb.return\nrt.cancel\nrt.return\npt.return\npt.cancel\nrt.cancel\nrt.return\npt.return")
    {
      complete = false;
      pump.execute(() => {sut.pt.inport.request(); sut.pt.inport.cancel();});
    }
    else
      throw (new dzn.runtime_error ("missing trace"));

    pump.wait ();
    pump.Dispose ();
  }
}
