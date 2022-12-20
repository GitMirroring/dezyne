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

class main
{
  public static void Main(String[] args)
  {
    Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
    Debug.AutoFlush = true;

    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    locator.set (runtime);
    using(double_collateral_blocking_shell sut = new double_collateral_blocking_shell (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.la.meta.require.name = "la";
      sut.la.meta.require.port = sut.la;
      sut.ra.meta.require.name = "ra";
      sut.ra.meta.require.port = sut.ra;

      bool toggle = true;
      sut.la.in_port.ping = () =>
      {
        System.Console.Error.WriteLine("sut.lbp.async.ping -> <external>.la.ping");
        System.Threading.Thread.Sleep(toggle ? 200 : 100);
        sut.la.out_port.pong();
        System.Console.Error.WriteLine("sut.lbp.async.return <- <external>.la.return");
      };

      sut.ra.in_port.ping = () =>
      {
        System.Console.Error.WriteLine("sut.rbp.async.ping -> <external>.ra.ping");
        System.Threading.Thread.Sleep(toggle ? 200 : 100);
        sut.ra.out_port.pong();
        System.Console.Error.WriteLine("sut.rbp.async.return <- <external>.ra.return");
      };

      for(int i = 0; i < 2; ++i)
      {
        System.Threading.Thread t1 = new System.Threading.Thread (() => {sut.right.in_port.hello ();});
        System.Threading.Thread t2 = new System.Threading.Thread (() => {
           System.Threading.Thread.Sleep(100);
           sut.left.in_port.hello ();
        });
        t1.Start();
        t2.Start();

        System.Threading.Thread.Sleep(50);
        sut.left.in_port.hello();

        t1.Join();
        t2.Join();

        toggle = !toggle;
      }
    }
  }
}
