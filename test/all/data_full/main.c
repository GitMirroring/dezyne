// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2017, 2019, 2021, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rutger van Beusekom <rutger@dezyne.org>
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

#include "data_full.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>

#include <assert.h>
#include <stdio.h>

void a0 (Idata_full* self)
{
 (void)self;
  fprintf (stdout, "a0 ()\n");
  fprintf (stderr, "sut.p.bottom.a0 -> <external>.port.a0\n");
}

void a (Idata_full* self, int i)
{
 (void)self;
  fprintf (stdout, "a (%d)\n", i);
  fprintf (stderr, "sut.p.bottom.a -> <external>.port.a\n");
}

void aa (Idata_full* self, int i, int j)
{
 (void)self;
  fprintf (stdout, "aa (%d,%d)\n", i, j);
  fprintf (stderr, "sut.p.bottom.aa -> <external>.port.aa\n");
}

void a6 (Idata_full* self, int i0, int i1, int i2,int i3, int i4, int i5)
{
 (void)self;
  fprintf (stdout, "a6 (%d,%d,%d,%d,%d,%d)\n", i0, i1, i2, i3, i4, i5);
  fprintf (stderr, "sut.p.bottom.a6 -> <external>.port.a6\n");
}

int main ()
{
  while (getchar () != EOF);

  dzn_locator l;
  dzn_locator_init (&l);

  data_full d;
#if defined (DZN_TRACING)
  dzn_meta m = {"d", 0};
#endif
  data_full_init (&d,&l
#if 1 // defined (DZN_TRACING)
                 ,&m
#endif
                 );
  d.port->meta.requires.name = "port";

  d.port->out.a0 = a0;
  d.port->out.a = a;
  d.port->out.aa = aa;
  d.port->out.a6 = a6;

  assert (Idata_full_Status_Yes == d.port->in.e0r (d.port));
  d.port->in.e0 (d.port);
  assert (Idata_full_Status_Yes == d.port->in.er (d.port,123));
  int i = 123;
  d.port->in.e (d.port,i);
  assert (i == 123);
  assert (Idata_full_Status_No == d.port->in.eer (d.port,123,345));

  d.port->in.eo (d.port,&i);
  assert (i == 234);

  int j = 0;
  d.port->in.eoo (d.port,&i,&j);
  assert (i == 123 && j == 456);

  d.port->in.eio (d.port,i,&j);
  assert (i == 123 && j == i);

  d.port->in.eio2 (d.port,&i);
  assert (i == 246);


  assert (Idata_full_Status_Yes == d.port->in.eor (d.port,&i));
  assert (i == 234);

  assert (Idata_full_Status_Yes == d.port->in.eoor (d.port,&i,&j));
  assert (i == 123 && j == 456);

  assert (Idata_full_Status_Yes == d.port->in.eior (d.port,i,&j));
  assert (i == 123 && j == i);

  assert (Idata_full_Status_Yes == d.port->in.eio2r (d.port,&i));
  assert (i == 246);

  return 0;
}
