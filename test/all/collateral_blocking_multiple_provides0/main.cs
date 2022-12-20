// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

public class DebugTraceListener: ConsoleTraceListener
{
  public override void Fail(string message)
  {
    base.Fail(message);
    Environment.Exit(1);
  }
}

class main
{
  public static void Main(String[] args)
  {
    Debug.Listeners.Add(new DebugTraceListener());
    Debug.AutoFlush = true;

    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    locator.set (runtime);
    using(collateral_blocking_multiple_provides0 sut = new collateral_blocking_multiple_provides0 (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.r.meta.require.name = "r";

      sut.r.in_port.hello = () =>
      {
        System.Console.Error.WriteLine("sut.bmp.r.hello -> <external>.r.hello");
        System.Threading.Thread.Sleep(200);
        sut.r.out_port.world();
        System.Console.Error.WriteLine("sut.bmp.r.return -> <external>.r.return");
      };
      var t = new System.Threading.Thread (() =>
      {
        System.Threading.Thread.Sleep(100);
        sut.right.in_port.hello ();
      });
      t.Start();

      sut.left.in_port.hello ();

      t.Join();
    }
  }
}
