// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

// -*-java-*-
using System;
using System.Diagnostics;

class main {
  public static void Main(String[] args) {
    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime(() => {System.Console.Error.WriteLine("illegal"); Environment.Exit(0);});
    implicit_illegal_requires sut = new implicit_illegal_requires(locator.set(runtime), "sut");
    sut.r.dzn_meta.provides.name = "r";
    sut.r.dzn_meta.provides.component = null;
    sut.r.outport.e();
    Environment.Exit(1);
  }
}
