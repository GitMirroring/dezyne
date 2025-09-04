// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2021, 2022, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

class main
{
  public static void Main (String[] args)
  {
    dzn.Locator locator = new dzn.Locator ();
    dzn.Runtime runtime = new dzn.Runtime ();
    hello_injected sut = new hello_injected (locator.set (runtime), "sut");

    sut.h.out_port.world = () => {System.Console.Error.WriteLine ("sut.m.h.world -> <external>.h.world");};
    sut.h.meta.require.name = "h";

    //dzn::check_bindings (sut);
    //dzn::dump_tree (sut);

    sut.h.in_port.hello ();
  }
}
