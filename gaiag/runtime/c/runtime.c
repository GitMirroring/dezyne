// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#include "runtime.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "mem.h"
#include "closure.h"
#include "queue.h"

typedef struct {
  int size;
  void (*f)(void*);
  void* self;
} arguments;

typedef struct {
  runtime_sub sub;
} component;

void
runtime_init (runtime* self)
{
  map_init (&self->queues);
}

void
runtime_sub_init (runtime* self, runtime_sub* sub)
{
  sub->rt = self;
  sub->handling = false;
  sub->q = dzn_calloc (sizeof (queue), 1);
}

bool*
runtime_handling (runtime_sub* sub)
{
  return &sub->handling;
}

void
runtime_flush (runtime_sub* sub)
{
  queue* q = sub->q;
  while (!queue_empty (q))
  {
    closure* c = queue_pop (q);
    c->func (c->args);
    free (c->args);
    free (c);
  }
}

void
runtime_defer (runtime_sub* sub, void (*event)(void*), void* args)
{
  closure *c = dzn_malloc (sizeof (closure));
  c->func = event;
  arguments *a = args;
  c->args = dzn_malloc (a->size);
  memcpy (c->args, a, a->size);
  queue_push (sub->q, c);
}

static void
runtime_handle_event (runtime_sub* sub, void (*event)(void*), void* args)
{
  bool* handle = runtime_handling (sub);
  if (!*handle)
  {
    *handle = true;
    event (args);
    runtime_flush (sub);
    *handle = false;
  }
  else
  {
    runtime_defer (sub, event, args);
  }
}

void
runtime_event (void (*event)(void*), void* args)
{
  arguments* a = args;
  component* c = a->self;
  runtime_handle_event (&c->sub, event, args);
}
