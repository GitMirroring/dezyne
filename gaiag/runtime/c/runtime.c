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
#include "pair.h"
#include "queue.h"

typedef struct {
  int size;
  void (*f)(void*);
  void* self;
} arguments;

typedef struct {
  runtime* rt;
} component;

typedef struct {
  void (*func)(void*);
  void *args;
} closure;


void
runtime_init (runtime* self)
{
  map_init (&self->queues);
}

static char*
runtime_key (void* scope)
{
  static char buf[sizeof (void*) * 2 + 3];
  sprintf (buf, "%p", scope);
  return buf;
}

static pair*
runtime_get (runtime* self, void* scope)
{
  void* p = 0;
  map_get (&self->queues, runtime_key (scope), &p);
  return p;
}

void
runtime_set (runtime* self, void* scope)
{
  queue* q = dzn_calloc (sizeof (queue), 1);
  pair* p = dzn_malloc (sizeof (pair));
  p->first = false;
  p->second = q;
  map_put (&self->queues, runtime_key (scope), p);
}

bool*
runtime_handling (runtime* self, void* scope)
{
  pair* p = runtime_get (self, scope);
  assert (p);
  return (bool*)&p->first;
}

void
runtime_flush (runtime* self, void* scope)
{
  pair* p = runtime_get (self, scope);
  if (p) {
    queue* q = p->second;
    while (!queue_empty (q))
    {
      closure* c = queue_pop (q);
      c->func (c->args);
      free (c->args);
      free (c);
    }
  }
}

void
runtime_defer (runtime* self, void* scope, void (*event)(void*), void* args)
{
  pair* p = runtime_get (self, scope);
  assert (p);
  closure *c = dzn_malloc (sizeof (closure));
  c->func = event;
  arguments *a = args;
  c->args = dzn_malloc (a->size);
  memcpy (c->args, a, a->size);
  queue_push (p->second, c);
}

static void
runtime_handle_event (runtime* self, void* scope, void (*event)(void*), void* args)
{
  bool* handle = runtime_handling (self, scope);
  if (!*handle)
  {
    *handle = true;
    event (args);
    runtime_flush (self, scope);
    *handle = false;
  }
  else
  {
    runtime_defer (self, scope, event, args);
  }
}

void
runtime_event (void (*event)(void*), void* args)
{
  arguments* a = args;
  component* c = a->self;
  runtime_handle_event (c->rt, c, event, args);
}
