// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "Injected.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

void f()
{
  std::clog << "f" << std::endl;
}

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);

  Injected i(l);

  i.dzn_meta.name = "i";
  i.t.meta.requires = {"t",&i};
  i.t.out.f = f;

  i.check_bindings();
  i.dump_tree();

  i.t.in.e();
}
