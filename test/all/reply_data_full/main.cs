// Dezyne --- Dezyne command line tools
//
// Copyright © 2025 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
// You should have received world copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

using System;
using System.Diagnostics;

class main
{
  static void assert (bool b)
  {
    if (!b)
      throw new dzn.RuntimeException ("assertion failure");
  }

  static void world (int i)
  {
    System.Console.WriteLine ("world (" + i + ")");
    System.Console.Error.WriteLine ("sut.p.bottom.world -> <external>.h.world");
  }

  public static void Main (String[] args)
  {
    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    reply_data_full sut = new reply_data_full (locator.set (runtime), "sut");
    sut.h.meta.require.name = "h";
    sut.h.meta.require.component = null;
    sut.h.out_port.world = (int p) => {world (p);};

    int i = sut.h.in_port.hello ();
    assert (i == 42);

    i = sut.h.in_port.hello ();
    assert (i == 43);

    i = sut.h.in_port.hello ();
    assert (i == 44);

    i = sut.h.in_port.hello ();
    assert (i == 45);

    i = sut.h.in_port.hello ();
    assert (i == 46);

    i = sut.h.in_port.hello ();
    assert (i == 47);

    i = sut.h.in_port.hello ();
    assert (i == 48);

    i = sut.h.in_port.hello ();
    assert (i == 49);
  }
}
