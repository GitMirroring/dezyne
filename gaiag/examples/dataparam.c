// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

void a0(IDataparam* self)
{
  (void)self;
  fprintf(stderr, "a0()\n");
}

void a(IDataparam* self, int i)
{
  (void)self;
  fprintf(stderr, "a(%d)\n", i);
}

void aa(IDataparam* self, int i, int j)
{
  (void)self;
  fprintf(stderr, "aa(%d, %d)\n", i, j);
}

void a6(IDataparam* self, int i0, int i1, int i2,int i3, int i4, int i5)
{
  (void)self;
  fprintf(stderr, "a6(%d,%d,%d,%d,%d,%d)\n", i0, i1, i2, i3, i4, i5);
}

int main()
{
  runtime rt;
  runtime_init(&rt);

  locator l;
  locator_init(&l, &rt);

  Datasystem d;
  meta m = {"d", 0};
  Datasystem_init(&d,&l,&m);
  d.port->out.name = "port";
  d.port->out.self = &d;

  d.port->out.a0 = a0;
  d.port->out.a = a;
  d.port->out.aa = aa;
  d.port->out.a6 = a6;

  assert(IDataparam_Status_Yes == d.port->in.e0r(d.port));
  d.port->in.e0(d.port);
  assert(IDataparam_Status_Yes == d.port->in.er(d.port,123));
  d.port->in.e(d.port,123);
  assert(IDataparam_Status_No == d.port->in.eer(d.port,123,345));

  int i = 0;
  d.port->in.eo(d.port,&i);
  assert(i == 234);

  int j = 0;
  d.port->in.eoo(d.port,&i,&j);
  assert(i == 123 && j == 456);

  d.port->in.eio(d.port,i,&j);
  assert(i == 123 && j == i);

  d.port->in.eio2(d.port,&i);
  assert(i == 246);


  assert(IDataparam_Status_Yes == d.port->in.eor(d.port,&i));
  assert(i == 234);

  assert(IDataparam_Status_Yes == d.port->in.eoor(d.port,&i,&j));
  assert(i == 123 && j == 456);

  assert(IDataparam_Status_Yes == d.port->in.eior(d.port,i,&j));
  assert(i == 123 && j == i);

  assert(IDataparam_Status_Yes == d.port->in.eio2r(d.port,&i));
  assert(i == 246);
  return 0;
}
