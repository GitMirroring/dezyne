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
#include "locator.h"
#include "queue.h"

typedef struct {
  int size;
  void (*f)(void*);
  void* self;
} arguments;

void
runtime_illegal_handler()
{
  assert(!"illegal");
}

void
runtime_init (runtime* self)
{
}

void
runtime_info_init (runtime_info* self, locator* loc)
{
  self->rt = loc->rt;
  self->locator = loc;
  self->handling = false;
  self->performs_flush = false;
  self->deferred = 0;
  queue_init(&self->q);
}

static void runtime_handle_event (runtime_info* info, void (*event)(void*), void* args);

void
runtime_flush (runtime_info* info)
{
  queue* q = &info->q;
  while (!queue_empty (q))
  {
#ifndef DZN_STATIC_QUEUES
    closure* c = queue_pop (q);
    runtime_handle_event (info, c->func, c->args);
    free (c->args);
    free (c);
#else
    closure c = *(closure*)queue_pop (q);
    runtime_handle_event (info, c.func, c.args);
#endif
  }
  if (info->deferred)
  {
    runtime_info* tgt = info->deferred;
    info->deferred = 0;
    if (tgt && !tgt->handling)
      runtime_flush (tgt);
  }
}

void
runtime_defer (void* vsrc, void* vtgt, void (*event)(void*), void* args)
{
  component* csrc = vsrc;
  component* ctgt = vtgt;
  runtime_info* src = csrc?&csrc->dzn_info:0;
  runtime_info* tgt = ctgt?&ctgt->dzn_info:0;
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
  queue_push (&tgt_info->q, &c);
  src->deferred = tgt;
#endif
}

static void
runtime_handle_event (runtime_info* info, void (*event)(void*), void* args)
{
  if (!info->handling)
  {
    info->handling = true;
    event (args);
    info->handling = false;
    runtime_flush (info);
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
  runtime_handle_event (&c->dzn_info, event, args);
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
  if (c->dzn_meta.parent) {
    strcpy (buf, p);
    strcpy (p, c->dzn_meta.name);
    if (strlen (buf))
      strcat (p, ".");
    return runtime_path (c->dzn_meta.parent, strcat (p, buf));
  }
  strcpy (buf, p);
  strcpy (p, c->dzn_meta.name);
  if (strlen (buf))
    strcat (p, ".");
  return strcat (p, buf);
}

void
runtime_trace_in (void* in, void* out, char const* e)
{
  char ibuf[1024] = "";
  char obuf[1024] = "";
  dzn_meta_t* i = in;
  dzn_meta_t* o = out;
  fprintf (stderr, "%s.%s.%s -> %s.%s.%s\n",
           runtime_path (o->parent, obuf), o->name, e,
           runtime_path (i->parent, ibuf), i->name, e);
}

void
runtime_trace_out (void* in, void* out, char const* e)
{
  char ibuf[1024] = "";
  char obuf[1024] = "";
  dzn_meta_t* i = in;
  dzn_meta_t* o = out;
  fprintf (stderr, "%s.%s.%s -> %s.%s.%s\n",
           runtime_path (i->parent, ibuf), i->name, e,
           runtime_path (o->parent, obuf), o->name, e);
}
