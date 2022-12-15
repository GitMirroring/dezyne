// Dezyne --- Dezyne command line tools
//
// Copyright © 2018, 2022 Rutger van Beusekom <rutger@dezyne.org>
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
    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    locator.set (runtime);
    calling_context sut = new calling_context (locator, "sut");
    sut.h.meta.require.name = "h";
    sut.w.meta.provide.name = "w";

    sut.w.in_port.world = (ref int c, int i) => {
      dzn.Runtime.trace (sut.w.meta, "world");
      if (c == 0)
        c = 123;
      else
      {
        Debug.Assert (c == 123);
        c = 456;
      }
      dzn.Runtime.trace_out (sut.w.meta, "return");
    };

    int cc = 0;
    sut.h.in_port.hello (ref cc, 123);
    Debug.Assert (cc == 456);
  }
}
