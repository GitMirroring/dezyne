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
    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    locator.set (runtime);
    using(collateral_blocking_multiple_provides sut = new collateral_blocking_multiple_provides (locator))
    {
      sut.dzn_meta.name = "sut";
      sut.world.dzn_meta.requires.name = "world";
      sut.world.dzn_meta.requires.port = sut.world;

      sut.world.inport.hello = () =>
      {
        System.Console.Error.WriteLine("sut.world.hello -> <external>.world.hello");
        System.Threading.Thread.Sleep(200);
        sut.world.outport.world();
        System.Console.Error.WriteLine("sut.world.return <- <external>.world.return");
      };

      sut.left.inport.hello();
      new System.Threading.Thread (() =>
      {
         sut.right.inport.hello ();
      }).Start();

      System.Threading.Thread.Sleep(50);

      sut.left.inport.hello();
      new System.Threading.Thread (() =>
      {
         sut.right.inport.hello ();
      }).Start();
    }
  }
}
