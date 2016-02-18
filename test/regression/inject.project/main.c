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

#include "Injected.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>

#include <stdio.h>

void f(itop* self)
{
  (void)self;
  fprintf(stderr, "f\n");
}

int main()
{
  runtime rt;
  runtime_init(&rt);

  locator l;
  locator_init(&l, &rt);

  Injected sut;
  dzn_meta_t mt = {"sut", 0};
  Injected_init(&sut, &l, &mt);
  sut.t->out.f = f;

  sut.t->in.e(sut.t);
  return 0;
}
