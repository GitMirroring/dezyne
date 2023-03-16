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
#include "calling_context.h"

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
sut_w_in_world (iworld* port, int* cc, int i)
{
  (void)i;
  dzn_runtime_trace (&port->meta, "world");
  if (*cc == 0) *cc = 123;
  else
    {
      assert (*cc == 123);
      *cc = 456;
    }
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

  calling_context sut;
  dzn_meta meta = {"sut", 0};
  calling_context_init (&sut, &locator, &meta);

  sut.h->meta.requires.name = "h";
  sut.w->meta.provides.name = "w";
  sut.w->in.world = sut_w_in_world;

  int cc = 0;
  sut.h->in.hello (sut.h, &cc, 123);

  return 0;
}
