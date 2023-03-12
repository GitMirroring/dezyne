// -*-comment-start: "//";comment-end:""-*-
// Dezyne --- Dezyne command line tools
// Copyright © 2023 Jan Nieuwenhuizen <janneke@gnu.org>
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

#define _GNU_SOURCE 1
#include "collateral_blocking_double_release.h"

#include <dzn/config.h>
#include <dzn/locator.h>
#include <dzn/runtime.h>
#include <dzn/pump.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char*
read_line ()
{
  char* line = 0;
  size_t size;
  int getline_result = getline (&line, &size, stdin);
  if (getline_result != -1)
  {
    size_t line_length = strlen (line);
    if ((line_length > 1) && (line[line_length-1] == '\n'))
      line[line_length-1] = '\0';
    return line;
  }
  return 0;
}

char*
read_trace ()
{
  static char trace[1024];
  char* line = read_line ();
  while (line)
    {
      strcat (trace, line);
      line = read_line ();
      if (line)
        strcat (trace, "\n");
    }
  return trace;
}

void
block1_release_in_hello (collateral_blocking_double_release* sut)
{
  sut->block1->in.hello (sut->block1);
  sut->release->in.hello (sut->release);
}

void
release_block0_in_hello (collateral_blocking_double_release* sut)
{
  sut->release->in.hello (sut->release);
  sut->block0->in.hello (sut->block0);
}


void
sut_w_in_hello (iworld* port)
{
  dzn_runtime_trace (&port->meta, "hello");
  dzn_runtime_trace_out (&port->meta, "return");
}

void
sut_w_in_cruel (iworld* port)
{
  dzn_runtime_trace (&port->meta, "cruel");
  dzn_runtime_trace_out (&port->meta, "return");
}

int
main ()
{
  dzn_locator locator;
  dzn_locator_init (&locator);
  dzn_pump pump;
  dzn_pump_init (&pump);
  dzn_locator_set (&locator, "pump", &pump);

  collateral_blocking_double_release sut;
  dzn_meta meta = {"sut", 0};
  collateral_blocking_double_release_init (&sut, &locator, &meta);

  sut.block0->meta.requires.name = "block0";
  sut.block1->meta.requires.name = "block1";
  sut.release->meta.requires.name = "release";
  sut.w->meta.provides.name = "w";
  sut.w->in.hello = sut_w_in_hello;
  sut.w->in.cruel = sut_w_in_cruel;

  dzn_closure sut_block0_in_hello = {(void (*)(void *))sut.block0->in.hello, sut.block0};
  dzn_closure sut_block1_in_hello = {(void (*)(void *))sut.block1->in.hello, sut.block1};
  dzn_closure sut_release_in_hello = {(void (*)(void *))sut.release->in.hello, sut.release};
  dzn_closure sut_block1_in_hello_sut_release_in_hello = {(void (*)(void *))block1_release_in_hello, &sut};
  dzn_closure sut_release_in_hello_sut_block0_in_hello = {(void (*)(void *))release_block0_in_hello, &sut};
  dzn_closure sut_w_out_world = {(void (*)(void *))sut.w->out.world, sut.w};

  char* trace = read_trace ();
  fprintf (stderr, "TRACE: >>>%s<<<\n", trace);
  if (0);
  // trace
  else if (!strcmp (trace, "block1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.hello\nw.hello\nw.return\nblock1.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return"))
  {
    dzn_pump_run (&pump, &sut_block1_in_hello_sut_release_in_hello);
    dzn_pump_run (&pump, &sut_release_in_hello_sut_block0_in_hello);
  }
  else if (!strcmp (trace, "block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nw.world\nw.cruel\nw.return\nblock0.return\nblock1.return"))
  {
    dzn_pump_run (&pump, &sut_block0_in_hello);
    dzn_pump_run (&pump, &sut_block1_in_hello);
    dzn_pump_run (&pump, &sut_w_out_world);
  }
  else if (!strcmp (trace, "block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return\nblock1.return"))
  {
    dzn_pump_run (&pump, &sut_block0_in_hello);
    dzn_pump_run (&pump, &sut_block1_in_hello);
    dzn_pump_run (&pump, &sut_release_in_hello);
  }
  else
  {
    fprintf (stderr, "missing trace\n");
    return 1;
  }

  // dzn_pump_wait () / dzn_pump_finalize ();

  return 0;
}
