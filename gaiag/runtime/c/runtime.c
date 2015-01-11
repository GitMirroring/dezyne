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

#include "runtime.h"

#include <assert.h>
#include <stdlib.h>

#include "callback.h"
#include "pair.h"
#include "queue.h"

void
runtime_init (runtime* self)
{
  map_init (&self->map);
}

static char*
runtime_key (void* scope)
{
  static char buf[sizeof (void*) * 2 + 3];
  sprintf (buf, "%p", scope);
  return buf;
}

pair*
runtime_get (runtime* self, void* scope)
{
  void* p;
  if (map_get (&self->map, runtime_key (scope), &p) == MAP_OK) {
    return p;
  }
  return 0;
}

void
runtime_set (runtime* self, void* scope)
{
  queue* q = malloc (sizeof (queue));
  pair* p = malloc (sizeof (pair));
  p->first = false;
  p->second = q;
  map_put (&self->map, runtime_key (scope), p);
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
      (*(void (*)(void*))queue_pop (q)) (scope);
    }
  }
}

void 
runtime_defer (runtime* self, void* scope, void *event)
{
  pair* p = runtime_get (self, scope);
  assert (p);
  queue_push (p->second, event);
}

void 
runtime_handle_event (runtime* self, void* scope, void* event)
{
  bool* handle = runtime_handling (self, scope);
  if (!*handle)
  {
    *handle = true;
    (*(void (*)(void*))event) (scope);
    runtime_flush (self, scope);
    *handle = false;
  }
  else
  {
    runtime_defer (self, scope, event);
  }
}

typedef struct {
  void (*callback)();
  void* self;
} closure;


typedef struct {
  runtime* rt;
} Component;

static void
handle_event (closure* c)
{
  Component* self = (Component*)(c->self);

  c->callback (c->self);
  runtime_flush (self->rt, c->self);
}

void
component_connect (void* self, void (**f)(void*), void* event)
{
  closure* event_closure = malloc (sizeof (closure));
  event_closure->callback = event;
  event_closure->self = self;
  *f = (void (*) (void*)) alloc_callback (handle_event, event_closure);
}
