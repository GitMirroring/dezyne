// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

    var sut = new foreign_requires (locator, "sut");
    sut.c.w0.inport.hello = () => {
        System.Console.Error.WriteLine("<external>.w0.hello -> sut.c.w0.world");
        System.Console.Error.WriteLine("<external>.w0.return <- sut.c.w0.return");
    };
    sut.c.w1.inport.hello = () => {
        System.Console.Error.WriteLine("<external>.w1.hello -> sut.c.w1.world");
        System.Console.Error.WriteLine("<external>.w1.return <- sut.c.w1.return");
    };
    sut.f.w0_world ();
    sut.f.w1_world ();
  }
}
