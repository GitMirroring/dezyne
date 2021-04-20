// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "foreign_optional.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void world(iworld* self)
{
  (void)self;
  fprintf(stderr, "<external>.h.world <- sut.c.h.world\n");
}

int main()
{
  while (getchar() != EOF);

  locator loc;
  locator_init(&loc);

  foreign_optional sut;
  sut.h = &sut.h_;
  sut.h->meta.provides.address = &sut;
  sut.h->meta.requires.address = 0;
  sut.f.base.w = &sut.f.base.w_;
  dzn_meta meta = {"sut", 0};
  foreign_optional_init(&sut, &loc, &meta);
  sut.c.h->out.world = &world;

  // FIXME
  sut.f.base.w->out.world = sut.c.h->out.world;
  Foreign_w_hello (&sut.f);
  return 0;
}
