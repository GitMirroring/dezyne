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
    Debug.Listeners.Add (new TextWriterTraceListener (Console.Error));
    Debug.Listeners.Add (new ThrowListener ());

    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    locator.set (runtime);
    sync_out_reply_binding sut = new sync_out_reply_binding (locator);

    sut.dzn_meta.name = "sut";

    sut.h.meta.require.name = "h";
    sut.h.meta.require.port = sut.h;

    sut.w.meta.provide.name = "w";
    sut.w.meta.provide.port = sut.w;

    sut.w.in_port.hello = () =>
    {
      dzn.Runtime.trace (sut.w.meta, "hello");
      sut.w.out_port.world ();
      dzn.Runtime.trace_out (sut.w.meta, "return");
    };

    sut.w.in_port.hello_void = () =>
    {
      dzn.Runtime.trace (sut.w.meta, "hello_void");
      sut.w.out_port.world_void ();
      dzn.Runtime.trace_out (sut.w.meta, "return");
    };

    string trace = read ();
    if (false);
    // trace
    else if (trace == "h.hello\nw.hello\nw.world\nw.return\nh.true")
    {
      int v = 0;
      sut.h.in_port.hello (ref v);
      Console.Error.WriteLine("v=" + v);
      Debug.Assert (v == 456);
    }
    else if (trace == "h.hello_void\nw.hello_void\nw.world_void\nw.return\nh.return")
    {
      int v = 0;
      sut.h.in_port.hello_void (ref v);
      Console.Error.WriteLine("v=" + v);
      Debug.Assert (v == 456);
    }
    else
      throw (new dzn.runtime_error ("missing trace"));
  }
}
