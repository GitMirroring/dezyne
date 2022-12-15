// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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
    using (blocking_multiple_provides2 sut
      = new blocking_multiple_provides2 (locator, "sut"))
    {
      sut.w_left.in_port.hello = () =>
      {
        System.Console.Error.WriteLine("sut.bmp.w_left.hello -> <external>.w_left.hello");
        new System.Threading.Thread (() =>
        {
          System.Threading.Thread.Sleep(100);
          sut.w_left.out_port.world();
        }).Start();
        System.Console.Error.WriteLine("sut.bmp.w_left.return -> <external>.w_left.return");
      };
      sut.w_right.in_port.hello = () =>
      {
        System.Console.Error.WriteLine("sut.bmp.w_right.hello -> <external>.w_right.hello");
        new System.Threading.Thread (() =>
        {
          System.Threading.Thread.Sleep(150);
          sut.w_right.out_port.world();
        }).Start();
        System.Console.Error.WriteLine("sut.bmp.w_right.return -> <external>.w_right.return");
      };
      new System.Threading.Thread (() =>
      {
        sut.h_left.in_port.hello ();
      }).Start();
      System.Threading.Thread.Sleep(50);
      sut.h_right.in_port.hello ();
    }
  }
}
