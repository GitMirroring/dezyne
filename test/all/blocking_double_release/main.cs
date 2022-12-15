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

class main
{
  public static void Main(String[] args)
  {
    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    locator.set (runtime);
    using (blocking_double_release sut
      = new blocking_double_release (locator, "sut"))
    {
      System.Threading.Thread f0 = new System.Threading.Thread (() =>
      {
         sut.block0.in_port.hello ();
      });
      f0.Start ();
      System.Threading.Thread.Sleep(100);

      System.Threading.Thread f1 = new System.Threading.Thread (() =>
      {
         sut.block1.in_port.hello ();
      });
      f1.Start ();
      System.Threading.Thread.Sleep(100);
      sut.release.in_port.hello ();

      f0.Join ();
      f1.Join ();
    }
  }
}
