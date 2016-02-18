// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Injected.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <iostream>

void f()
{
  std::clog << "f" << std::endl;
}

int main()
{
  dzn::locator l;
  dzn::runtime rt;
  l.set(rt);

  Injected sut(l);
  sut.dzn_meta.name = "sut";
  // sut.t.meta.provides = {"t", 0};
  sut.t.meta.requires = {"t", 0};
  sut.t.meta.provides = {"t", 0};
  sut.t.out.f = f;

  sut.check_bindings();
  sut.dump_tree();

  sut.t.in.e();
}
