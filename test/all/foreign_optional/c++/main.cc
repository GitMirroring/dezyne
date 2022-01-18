// Dezyne --- Dezyne command line tools
//
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

#include "foreign_optional.hh"

#include <limits>

int
main(int argc, char* argv[])
{
  std::cin.ignore(std::numeric_limits<std::streamsize>::max());

  dzn::locator l;
  dzn::runtime rt;
  l.set(rt);

  foreign_optional sut(l);
  sut.dzn_meta.name = "sut";

  sut.c.h.out.world = [] {std::clog << "<external>.h.world <- sut.c.h.world\n";};
  sut.f.w_hello ();
}
