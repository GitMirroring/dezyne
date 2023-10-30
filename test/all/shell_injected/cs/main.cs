// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2023 Rutger van Beusekom <rutger@dezyne.org>
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

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

class main {
  public static void Main(String[] args)
  {
    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    using(shell_injected sut = new shell_injected (locator.set(runtime), "shell_injected"))
    {
      sut.p.out_port.f = () =>
      {
          System.Console.Error.WriteLine("<external>.p.f <- shell_injected.top.p.f");
      };
      sut.r.in_port.e = () => {
          System.Console.Error.WriteLine("<external>.r.e <- shell_injected.top.r.e");
          System.Console.Error.WriteLine("<external>.r.return <- shell_injected.top.r.return");
      };

      Thread t = new Thread (() => {
        Thread.Sleep (50);
        sut.r.out_port.f ();
        });
      t.Start ();
      sut.p.in_port.e ();
      t.Join ();
    }
  }
}
