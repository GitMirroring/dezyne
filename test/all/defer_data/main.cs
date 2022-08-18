// Dezyne --- Dezyne command line tools
//
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

public class ThrowListener : TextWriterTraceListener
{
    public override void Fail(string message)
    {
        throw new Exception(message);
    }

    public override void Fail(string message, string detailMessage)
    {
        throw new Exception(message);
    }
}

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
    // Debug.Listeners.Add (new ThrowListener ());
    // Debug.AutoFlush = true;

    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    locator.set (runtime);
    defer_data sut = new defer_data (locator);
    dzn.pump pump = new dzn.pump ();
    locator.set (pump);

    sut.dzn_meta.name = "sut";

    sut.h.dzn_meta.requires.name = "h";
    sut.h.dzn_meta.requires.port = sut.h;

    sut.h.outport.world = (int i) =>
    {
      dzn.Runtime.traceIn (sut.h.dzn_meta, "world");
    };

    string trace = read ();
    if (false);
    // trace
    else if (trace == "h.hello\nh.return\nh.hi\nh.return\n<defer>\nh.world")
    {
        pump.execute (() => {sut.h.inport.hello (0);});
        pump.execute (() => {sut.h.inport.hi (0);});
    }
    else if (trace == "h.hello\nh.return\nh.cruel\nh.return\n<defer>\nh.world")
    {
        pump.execute (() => {sut.h.inport.hello (0);});
        pump.execute (() => {sut.h.inport.cruel (1);});
    }
    else
      throw (new dzn.runtime_error ("missing trace"));

    pump.wait ();
    pump.Dispose ();
  }
}
