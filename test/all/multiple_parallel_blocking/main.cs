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
    using(multiple_parallel_blocking sut = new multiple_parallel_blocking (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.eleft.dzn_meta.requires.name = "eleft";
      sut.eright.dzn_meta.requires.name = "eright";
      sut.rleft.dzn_meta.requires.name = "rleft";
      sut.rright.dzn_meta.requires.name = "rright";

      Object condition = new Object();
      int count = 0;
      sut.eleft.inport.hello = () =>
      {
        Console.Error.WriteLine("sut.left.e.hello -> <external>.eleft.hello");
        new Thread (() =>
        {
          Thread.Sleep(50);
          sut.eleft.outport.world();

          lock(condition)
          {
            ++count;
            if(count == 6) Monitor.Pulse(condition);
          }
        }).Start();
        Console.Error.WriteLine("sut.left.e.return -> <external>.eleft.return");
      };
      sut.eright.inport.hello = () =>
      {
        Console.Error.WriteLine("sut.right.e.hello -> <external>.eright.hello");
        new Thread (() =>
        {
          Thread.Sleep(100);
          sut.eright.outport.world();

          lock(condition)
          {
            ++count;
            if(count == 6) Monitor.Pulse(condition);
          }
        }).Start();
        Console.Error.WriteLine("sut.right.e.return -> <external>.eright.return");
      };
      sut.rleft.inport.hello = () =>
      {
        Console.Error.WriteLine("sut.left.r.hello -> <external>.rleft.hello");
        new Thread (() =>
        {
          Thread.Sleep(200);
          sut.rleft.outport.world();

          lock(condition)
          {
            ++count;
            if(count == 6) Monitor.Pulse(condition);
          }
        }).Start();
        Console.Error.WriteLine("sut.left.r.return -> <external>.rleft.return");
      };
      sut.rright.inport.hello = () =>
      {
        Console.Error.WriteLine("sut.right.r.hello -> <external>.rright.hello");
        new Thread (() =>
        {
          Thread.Sleep(400);
          sut.rright.outport.world();

          lock(condition)
          {
            ++count;
            if(count == 6) Monitor.Pulse(condition);
          }
        }).Start();
        Console.Error.WriteLine("sut.right.r.return -> <external>.rright.return");
      };
      var t = new Thread (() =>
      {
        Thread.Sleep(50);
        sut.pright.inport.hello();
      });
      t.Start();
      sut.pleft.inport.hello();
      t.Join();

      lock(condition)
      {
        while(count != 6) Monitor.Wait(condition);
      }
    }
  }
}
