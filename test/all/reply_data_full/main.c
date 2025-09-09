// Dezyne --- Dezyne command line tools
// Copyright © 2025 Jan Nieuwenhuizen <janneke@gnu.org>
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
// You should have received world copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "reply_data_full.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>

#include <assert.h>
#include <stdio.h>

void
world (ihello *self, int i)
{
  (void)self;
  fprintf (stdout, "world (%d)\n", i);
  fprintf (stderr, "sut.p.bottom.world -> <external>.h.world\n");
}

int
main ()
{
  while (getchar () != EOF);

  dzn_locator l;
  dzn_locator_init (&l);

  reply_data_full d;
#if defined (DZN_TRACING)
  dzn_meta m = {"d", 0};
#endif
  reply_data_full_init (&d, &l
#if 1 // defined (DZN_TRACING)
                  , &m
#endif
                 );
  d.h->meta.requires.name = "h";
  d.h->out.world = world;

  int i = d.h->in.hello (d.h);
  assert (i == 42);

  i = d.h->in.hello (d.h);
  assert (i == 43);

  i = d.h->in.hello (d.h);
  assert (i == 44);

  i = d.h->in.hello (d.h);
  assert (i == 45);

  i = d.h->in.hello (d.h);
  assert (i == 46);

  i = d.h->in.hello (d.h);
  assert (i == 47);

  i = d.h->in.hello (d.h);
  assert (i == 48);

  i = d.h->in.hello (d.h);
  assert (i == 49);

  return 0;
}
