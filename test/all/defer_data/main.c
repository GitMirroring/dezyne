// -*-comment-start: "//";comment-end:""-*-
// Dezyne --- Dezyne command line tools
// Copyright © 2023, 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
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
#include "defer_data.h"

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
sut_h_out_world (ihello *port)
{
  dzn_runtime_trace (&port->meta, "world");
}

int
main ()
{
  dzn_locator locator;
  dzn_locator_init (&locator);
  dzn_pump pump;
  dzn_pump_init (&pump);
  dzn_locator_set (&locator, "pump", &pump);

  defer_data sut;
  dzn_meta meta = {"sut", 0};
  defer_data_init (&sut, &locator, &meta);

  sut.h->meta.requires.name = "h";
  sut.h->out.world = (void (*) (ihello*, int)) sut_h_out_world;

  dzn_closure sut_h_in_hello = { (void (*) (void *)) sut.h->in.hello, sut.h};
  dzn_closure sut_h_in_hi = { (void (*) (void *)) sut.h->in.hi, sut.h};
  dzn_closure sut_h_in_cruel = { (void (*) (void *)) sut.h->in.cruel, sut.h};

  char *trace = read_trace ();
  if (0);
  // trace
  else if (!strcmp (trace, "h.hello\nh.return\nh.hi\nh.return\n<defer>\nh.world"))
    {
      dzn_pump_run (&pump, &sut_h_in_hello); // 0
      dzn_pump_run (&pump, &sut_h_in_hi);  // 0
    }
  else if (!strcmp (trace, "h.hello\nh.return\nh.cruel\nh.return\n<defer>\nh.world"))
    {
      dzn_pump_run (&pump, &sut_h_in_hello); // 0
      dzn_pump_run (&pump, &sut_h_in_cruel); // 1
    }
  else
    {
      fprintf (stderr, "missing trace\n");
      return 1;
    }

  dzn_pump_finalize (&pump);

  return 0;
}
