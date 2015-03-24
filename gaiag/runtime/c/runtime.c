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
#include "trio.h"
#include "queue.h"

typedef struct {
  int size;
  void (*f)(void*);
  void* self;
} arguments;

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

static trio*
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
  trio* p = dzn_malloc (sizeof (trio));
  p->first = false;
  p->second = 0;
  p->third = q;
  map_put (&self->queues, runtime_key (scope), p);
}

static bool*
runtime_handling (runtime* self, void* scope)
{
  trio* p = runtime_get (self, scope);
  assert (p);
  return (bool*)&p->first;
}

static void**
runtime_deferred (runtime* self, void* scope)
{
  trio* p = runtime_get (self, scope);
  assert (p);
  return &p->second;
}

static queue*
runtime_queue (runtime* self, void* scope)
{
  trio* p = runtime_get (self, scope);
  assert (p);
  return p->third;
}

static bool*
runtime_external (runtime* self, void* scope)
{
  return false; // FIXME Paul
}

static void runtime_handle_event (runtime* self, void* scope, void (*event)(void*), void* args);

void
runtime_flush (runtime* self, void* scope)
{
  if (runtime_external (self, scope))
    return;
  trio* p = runtime_get (self, scope);
  //printf ("flush: %p\n", scope);
  if (p) {
    queue* q = p->third;
    while (!queue_empty (q))
    {
      closure* c = queue_pop (q);
      runtime_handle_event (self, scope, c->func, c->args);
      free (c->args);
      free (c);
    }
  }
  if (runtime_deferred (self, scope))
  {
    void** target = runtime_deferred (self, scope);
    *runtime_deferred (self, scope) = 0;
    if (*target && !runtime_handling (self, *target))
      runtime_flush (self, *target);
  }
}

void
runtime_defer (runtime* self, void* vin, void* vout, void (*event)(void*), void* args)
{
  if (runtime_external (self, vin) || runtime_external (self, vout))
  {
    runtime_handle_event (self, vout, event, args);
    return;
  }
  component* in = vin;
  trio* p = runtime_get (self, in);
  assert (p);
  closure *c = dzn_malloc (sizeof (closure));
  c->func = event;
  arguments *a = args;
  c->args = dzn_malloc (a->size);
  memcpy (c->args, a, a->size);
  queue_push (p->third, c);
}

static void
runtime_handle_event (runtime* self, void* scope, void (*event)(void*), void* args)
{
  bool* handle = runtime_handling (self, scope);
  //printf ("handle: %p, %d\n", scope, *handle);
  if (!*handle)
  {
    *handle = true;
    event (args);
    *handle = false;
    runtime_flush (self, scope);
  }
  else
  {
    assert(!"component already handling an event");
  }
}

void
runtime_event (void (*event)(void*), void* args)
{
  arguments* a = args;
  component* c = a->self;
  runtime_handle_event (c->rt, c, event, args);
}

char*
runtime_path (void *m, char* p)
{
  char buf[1023];
  if (!m) {
    strcpy (buf, p);
    strcpy (p, "null.");
    strcat (p, buf);
    return p;
  }
  component *c = m;
  //if (m.component) {
  //  return runtime.path(m.component.meta, m.name + (p ? "." + p : p));
  // }
  if (c->m.parent) {
    strcpy (buf, p);
    strcpy (p, c->m.name);
    if (strlen (buf))
      strcat (p, ".");
    return runtime_path (c->m.parent, strcat (p, buf));
  }
  strcpy (buf, p);
  strcpy (p, c->m.name);
  if (strlen (buf))
    strcat (p, ".");
  return strcat (p, buf);
}

void
runtime_trace_in (void* in, void* out, char const* e)
{
  char ibuf[1024] = "";
  char obuf[1024] = "";
  meta* i = in;
  meta* o = out;
  fprintf (stderr, "%s.%s.%s -> %s.%s.%s\n",
           runtime_path (o->parent, obuf), o->name, e,
           runtime_path (i->parent, ibuf), i->name, e);
}

void
runtime_trace_out (void* in, void* out, char const* e)
{
  char ibuf[1024] = "";
  char obuf[1024] = "";
  meta* i = in;
  meta* o = out;
  fprintf (stderr, "%s.%s.%s -> %s.%s.%s\n",
           runtime_path (i->parent, ibuf), i->name, e,
           runtime_path (o->parent, obuf), o->name, e);
}
