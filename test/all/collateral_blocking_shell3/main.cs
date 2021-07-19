// Dezyne --- Dezyne command line tools

// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    locator.set (runtime);
    using(collateral_blocking_shell3 sut = new collateral_blocking_shell3 (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.w0.dzn_meta.requires.name = "w0";
      sut.w1.dzn_meta.requires.name = "w1";

      sut.h.outport.bye = () =>
      {
        System.Console.Error.WriteLine("<external>.h.bye <- sut.top.h.bye");
      };
      sut.w0.inport.hello = () =>
      {
        System.Console.Error.WriteLine("sut.blocked.w0.hello -> <external>.w0.hello");
      };
      sut.w1.inport.hello = () =>
      {
        System.Console.Error.WriteLine("sut.blocked.w1.hello -> <external>.w1.hello");

        new System.Threading.Thread (() =>
        {
          System.Threading.Thread.Sleep(2000);
          System.Console.Error.WriteLine("world0");
          sut.w0.outport.world ();
          System.Threading.Thread.Sleep(2000);
          System.Console.Error.WriteLine("world1");
          sut.w1.outport.world ();
        }).Start();
      };
      sut.w2.inport.hello = () =>
      {
        System.Console.Error.WriteLine("sut.top.w1.hello -> <external>.w2.hello");
        sut.w2.outport.world();
      };

      sut.h.inport.hello ();
    }
  }
}
