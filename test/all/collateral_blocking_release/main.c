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
#include "collateral_blocking_release.h"

#include <dzn/config.h>
#include <dzn/locator.h>
#include <dzn/runtime.h>
#include <dzn/pump.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *
read_line ()
{
  char *line = 0;
  size_t size;
  int getline_result = getline (&line, &size, stdin);
  if (getline_result != -1)
    {
      size_t line_length = strlen (line);
      if ((line_length > 1) && (line[line_length - 1] == '\n'))
        line[line_length - 1] = '\0';
      return line;
    }
  return 0;
}

char *
read_trace ()
{
  static char trace[1024];
  char *line = read_line ();
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
in_hello_twice (void *self)
{
  ihello *port = self;
  port->in.hello (port);
  port->in.hello (port);
}

void
sut_w_in_hello (iworld *port)
{
  dzn_runtime_trace (&port->meta, "hello");
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

  collateral_blocking_release sut;
  dzn_meta meta = {"sut", 0};
  collateral_blocking_release_init (&sut, &locator, &meta);

  sut.block->meta.requires.name = "block";
  sut.release->meta.requires.name = "release";
  sut.w->meta.provides.name = "w";
  sut.w->in.hello = sut_w_in_hello;

  dzn_closure sut_block_in_hello = { (void (*) (void *))sut.block->in.hello, sut.block};
  dzn_closure sut_release_in_hello = { (void (*) (void *))sut.release->in.hello, sut.release};
  dzn_closure sut_release_in_hello_sut_release_in_hello = {in_hello_twice, sut.release};
  dzn_closure sut_w_out_world = { (void (*) (void *))sut.w->out.world, sut.w};

  char *trace = read_trace ();
  fprintf (stderr, "TRACE: >>>%s<<<\n", trace);
  if (0);
  // trace
  else if (!strcmp (trace, "block.hello\nw.hello\nw.return\nrelease.hello\nw.hello\nw.return\nrelease.return\nrelease.hello\nrelease.return\nblock.return"))
    {
      dzn_pump_run (&pump, &sut_block_in_hello);
      dzn_pump_run (&pump, &sut_release_in_hello_sut_release_in_hello);
    }
  else if (!strcmp (trace, "block.hello\nw.hello\nw.return\nw.world\nblock.return"))
    {
      dzn_pump_run (&pump, &sut_block_in_hello);
      dzn_pump_run (&pump, &sut_w_out_world);
    }
  else if (!strcmp (trace, "release.hello\nrelease.return"))
    dzn_pump_run (&pump, &sut_release_in_hello);
  else
    {
      fprintf (stderr, "missing trace\n");
      return 1;
    }

  return 0;
}
