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

void
runtime_init (runtime* self)
{
  (void)self;
}

void
runtime_sub_init (runtime* self, runtime_sub* sub)
{
  sub->rt = self;
  sub->handling = false;
  sub->performs_flush = false;
  sub->deferred = 0;
  queue_init(&sub->q);
}

static void runtime_handle_event (runtime_sub* sub, void (*event)(void*), void* args);

void
runtime_flush (runtime_sub* sub)
{
  queue* q = &sub->q;
  while (!queue_empty (q))
  {
#ifndef DZN_STATIC_QUEUES
    closure* c = queue_pop (q);
    runtime_handle_event (sub, c->func, c->args);
    free (c->args);
    free (c);
#else
    closure c = *(closure*)queue_pop (q);
    runtime_handle_event (sub, c.func, c.args);
#endif
  }
  if (sub->deferred)
  {
    runtime_sub* tgt = sub->deferred;
    sub->deferred = 0;
    if (tgt && !tgt->handling)
      runtime_flush (tgt);
  }
}

void
runtime_defer (void* vsrc, void* vtgt, void (*event)(void*), void* args)
{
  component* csrc = vsrc;
  component* ctgt = vtgt;
  runtime_sub* src = csrc?&csrc->sub:0;
  runtime_sub* tgt = ctgt?&ctgt->sub:0;
  if ((!(src && src->performs_flush)) && !(tgt->handling))
  {
    runtime_handle_event (tgt, event, args);
    return;
  }
#ifndef DZN_STATIC_QUEUES
  closure *c = dzn_malloc (sizeof (closure));
  c->func = event;
  arguments *a = args;
  c->args = dzn_malloc (a->size);
  memcpy (c->args, a, a->size);
  queue_push (&tgt->q, c);
  src->deferred = tgt;
#else
  closure c;
  c.func = event;
  arguments *a = args;
  assert(a->size <= DZN_MAX_ARGS_SIZE);
  memcpy(&c.args, a, a->size);
  queue_push (&tgt_sub->q, &c);
  src->deferred = tgt;
#endif
}

static void
runtime_handle_event (runtime_sub* sub, void (*event)(void*), void* args)
{
  if (!sub->handling)
  {
    sub->handling = true;
    event (args);
    sub->handling = false;
    runtime_flush (sub);
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
  runtime_handle_event (&c->sub, event, args);
}

char*
runtime_path (void *m, char* p)
{
  char buf[1023];
  if (!m) {
    strcpy (buf, p);
    strcpy (p, "<external>");
    strcat (p, buf);
    return p;
  }
  component *c = m;
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
