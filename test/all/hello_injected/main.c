// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2019, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "hello_injected.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>

#include <stdio.h>
#include <stdlib.h>

void
f (itop* self)
{
  (void)self;
  fprintf(stderr, "sut.m.t.f -> <external>.t.f\n");
}

int
main ()
{
  while (getchar () != EOF);

  dzn_locator locator;
  dzn_locator_init (&locator);

  hello_injected sut;
  dzn_meta meta = {"sut", 0};
  hello_injected_init (&sut, &locator, &meta);
  sut.t->meta.requires.name = "t";
  sut.t->meta.requires.component = 0;
  sut.t->out.f = f;

  sut.t->in.e (sut.t);
  return 0;
}
