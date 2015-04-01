// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


// handwritten generic main
#include "runtime.hh"
#include "locator.hh"

#include "Main.hh"

#include <iostream>

int main()
{
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);

  dezyne::Main m(l);

  m.dzn_meta.name = "m";
  m.runner.meta.requires = {"p", &m};

  m.check_bindings();
  m.dump_tree();

  m.runner.in.run();
}
