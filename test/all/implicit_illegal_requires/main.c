// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "implicit_illegal_requires.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>

#include <stdlib.h>

void illegal_print() {
  fputs("illegal\n", stderr);
  exit(0);
}

int main()
{
  while (getchar() != EOF);

  locator loc;
  locator_init(&loc);
  loc.illegal = illegal_print;

  implicit_illegal_requires sut;

  dzn_meta m = {"sut", 0};
  implicit_illegal_requires_init(&sut, &loc, &m);
  sut.r->meta.provides.port = "r";
  sut.r->out.e(sut.r);

  return 1;
}
