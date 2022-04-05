// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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

    bool once = true;

    using(collateral_blocking_reorder sut = new collateral_blocking_reorder (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.r.dzn_meta.requires.name = "r";
      sut.e.dzn_meta.requires.name = "e";

      sut.r.inport.hello = () =>
      {
        System.Console.Error.WriteLine("sut.block.r.hello -> <external>.r.hello");
        new System.Threading.Thread (() =>
        {
          if(once) {once = false; sut.e.outport.world ();}
          sut.r.outport.world ();
        }).Start();
        System.Console.Error.WriteLine("sut.block.r.return <- <external>.r.return");
      };
      sut.e.inport.hello = () =>
      {
        System.Console.Error.WriteLine("sut.proxy.e.hello -> <external>.e.hello");
        System.Console.Error.WriteLine("sut.proxy.e.return <- <external>.e.return");
      };

      sut.p.inport.hello ();

      dzn.pump pump = sut.dzn_locator.get<dzn.pump>();
      pump.wait ();
    }
  }
}
