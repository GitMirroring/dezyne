// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "Tiny.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>

static void console_detected()
{
  DZN_TRACE(__FUNCTION__);
}

static void console_deactivated()
{
  DZN_TRACE(__FUNCTION__);
}

static void sensor_enable()
{
  DZN_TRACE(__FUNCTION__);
}

static void sensor_disable()
{
  DZN_TRACE(__FUNCTION__);
}

bool sounding = false;
static void siren_turnon()
{
  if (sounding)
    *(int*)0 = 0; // SEGFAULT here: Tiny C test
  sounding = true;
  DZN_TRACE(__FUNCTION__);
}

static void siren_turnoff()
{
  sounding = false;
  DZN_TRACE(__FUNCTION__);
}

int main(int argc)
{
  runtime rt;
  runtime_init(&rt);

  locator l;
  locator_init(&l, &rt);

  Tiny sut;
#if defined(DZN_TRACING)
  dzn_meta_t mt = {"sut", 0};
#endif
  Tiny_init(&sut, &l
#if defined(DZN_TRACING)
                , &mt
#endif
                );

  sut.console->out.detected = console_detected;
  sut.console->out.deactivated = console_deactivated;
  sut.sensor->in.enable = sensor_enable;
  sut.sensor->in.disable = sensor_disable;
  sut.siren->in.turnon = siren_turnon;
  sut.siren->in.turnoff = siren_turnoff;

  sut.sensor->meta.requires.address = &sut;
  sut.siren->meta.requires.address = &sut;

  sut.console->in.arm(sut.console);
  sut.sensor->out.triggered(sut.sensor);
  runtime_flush(&sut.dzn_info);
  
  sut.console->in.disarm(sut.console);
  sut.sensor->out.disabled(sut.sensor);
  runtime_flush(&sut.dzn_info);

  if (argc == 1) return 0;
  // Tiny C test: add dummy argument to trigger segfault
  sut.console->in.arm(sut.console);
  sut.sensor->out.triggered(sut.sensor);
  runtime_flush(&sut.dzn_info);

  return 0;
}
