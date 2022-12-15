// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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
using System.Threading;

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
    using (collateral_blocking_reorder_parallel sut
      = new collateral_blocking_reorder_parallel (locator, "sut"))
    {
      sut.eleft.meta.require.name = "eleft";
      sut.eright.meta.require.name = "eright";
      sut.rleft.meta.require.name = "rleft";
      sut.rright.meta.require.name = "rright";

      bool once_left = true;

      sut.eleft.in_port.hello = () =>
      {
        Console.Error.WriteLine("sut.left.e.hello -> <external>.eleft.hello");
        Console.Error.WriteLine("sut.left.e.return -> <external>.eleft.return");
      };
      sut.eright.in_port.hello = () =>
      {
        Console.Error.WriteLine("sut.right.e.hello -> <external>.eright.hello");
        Console.Error.WriteLine("sut.right.e.return -> <external>.eright.return");
      };
      sut.rleft.in_port.hello = () =>
      {
        Console.Error.WriteLine("sut.left.r.hello -> <external>.rleft.hello");
        Thread.Sleep(100);
        if(once_left) {once_left = false; sut.eleft.out_port.world();}
        Thread.Sleep(100);
        sut.rleft.out_port.world();
        Thread.Sleep(100);
        Console.Error.WriteLine("sut.left.r.return -> <external>.rleft.return");
      };
      sut.rright.in_port.hello = () =>
      {
        Console.Error.WriteLine("sut.right.r.hello -> <external>.rright.hello");
        Thread.Sleep(200);
        sut.rright.out_port.world();
        Thread.Sleep(100);
        Console.Error.WriteLine("sut.right.r.return -> <external>.rright.return");
      };
      var t = new Thread (() =>
      {
        Thread.Sleep(50);
        sut.pright.in_port.hello();
      });
      t.Start();
      sut.pleft.in_port.hello();
      t.Join();

      dzn.pump pump = sut.dzn_locator.get<dzn.pump>();
      pump.wait ();
    }
  }
}
