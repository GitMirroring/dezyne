// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

    using (collateral_blocking_shell2 sut
      = new collateral_blocking_shell2 (locator, "sut"))
    {
      sut.w.meta.provide.name = "w";

      sut.w.in_port.hello = () =>
      {
        dzn.Runtime.trace(sut.w.meta, "hello");

        new System.Threading.Thread (() =>
        {
          System.Threading.Thread.Sleep(50);
          System.Console.Error.WriteLine("cruel");
          sut.h.in_port.cruel ();
        }).Start();
        new System.Threading.Thread (() =>
        {
          System.Threading.Thread.Sleep(100);
          System.Console.Error.WriteLine("world");
          sut.w.out_port.world ();
        }).Start();

        dzn.Runtime.trace_out(sut.w.meta, "return");
      };

      System.Console.Error.WriteLine("hello happy");
      sut.h.in_port.hello ();
    }
  }
}
