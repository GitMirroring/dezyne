// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

class main {

  public static void Main(String[] args) {
    var locator = new dzn.Locator();
    var runtime = new dzn.Runtime();
    locator.set(runtime);

    var sut = new foreign_optional(locator, "sut");
    sut.c.h.outport.world = () => {
        System.Console.Error.WriteLine("<external>.h.world <- sut.c.h.world");
    };
    sut.f.w_hello ();
  }
}
