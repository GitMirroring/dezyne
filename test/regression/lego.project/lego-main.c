// Dezyne --- Dezyne command line tools
//
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

#include "imotor.h"
#include "ilight.h"
#include "itouch.h"
#include "itimer_impl.h"
#include "timer.h"

#include "LegoBallSorter.h"

#include <dzn/runtime.h>
#include <dzn/locator.h>

void
timer_impl_create (itimer_impl* self, int ms)
{
  fprintf (stderr, "%s\n", __FUNCTION__);
}

void
timer_impl_cancel (itimer_impl* self)
{
  fprintf (stderr, "%s\n", __FUNCTION__);
}

int main(int argc, char** argv)
{
  runtime dezyne_runtime;
  runtime_init (&dezyne_runtime);

  locator dezyne_locator;
  locator_init (&dezyne_locator, &dezyne_runtime);

  LegoBallSorter sut;
  dzn_meta_t m = {"sut", 0};
  LegoBallSorter_init(&sut, &dezyne_locator, &m);
  sut.ctrl->out.name = "ctrl";
  sut.ctrl->out.self = &sut;
}
