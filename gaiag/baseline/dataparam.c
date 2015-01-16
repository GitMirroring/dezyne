// Dezyne --- Dezyne command line tools
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

#include "Datasystem.h"

#include "locator.h"
#include "runtime.h"

#include <assert.h>
#include <stdio.h>

void a0()
{
  printf ("a0()\n");
}

void a(void* self, int i)
{
  (void)self;
  printf ("a(%d)\n", i);
}

void aa(void* self, int i, int j)
{
  (void)self;
  printf ("a(%d, %d)\n", i, j);
}

void a6(void* self, int i0, int i1, int i2,int i3, int i4, int i5)
{
  (void)self;
  printf ("a6(%d,%d,%d,%d,%d,%d)\n", i0, i1, i2, i3, i4, i5);
}

int main()
{
  runtime rt;
  runtime_init (&rt);

  locator l;
  locator_init (&l, &rt);

  Dataparam c;
  Dataparam_init (&c,&l);

  c.port->out.a0 = a0;
  c.port->out.a = a;
  c.port->out.aa = aa;
  c.port->out.a6 = a6;

  assert(Status_Yes == c.port->in.e0r(c.port));
  c.port->in.e0(c.port);
  assert(Status_No == c.port->in.er(c.port,123));
  c.port->in.e(c.port,123);
  assert(Status_No == c.port->in.eer(c.port,123,345));

  int i = 0;
  c.port->in.eo(c.port,&i);
  assert(i == 234);

  int j = 0;
  c.port->in.eoo(c.port,&i,&j);
  assert(i == 123 && j == 456);

  c.port->in.eio(c.port,i,&j);
  assert(i == 123 && j == i);

  c.port->in.eio2(c.port,&i);
  assert(i == 246);


  assert(Status_Yes == c.port->in.eor(c.port,&i));
  assert(i == 234);

  assert(Status_Yes == c.port->in.eoor(c.port,&i,&j));
  assert(i == 123 && j == 456);

  assert(Status_Yes == c.port->in.eior(c.port,i,&j));
  assert(i == 123 && j == i);

  assert(Status_Yes == c.port->in.eio2r(c.port,&i));
  assert(i == 246);
  return 0;
}
