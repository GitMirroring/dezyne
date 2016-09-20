// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015, 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include <dzn/runtime.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <dzn/mem.h>
#include <dzn/closure.h>
#include <dzn/locator.h>
#include <dzn/queue.h>

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
  if (!(src && src->performs_flush) && !(tgt->handling))
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
  if (src)
    src->deferred = tgt;
#else
  closure c;
  c.func = event;
  arguments *a = args;
  assert(a->size <= DZN_MAX_ARGS_SIZE);
  memcpy(&c.args, a, a->size);
  queue_push (&tgt_info->q, &c);
  if (src)
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
runtime_path (dzn_meta_t const* m, char* p)
{
  char buf[1024] = "";
  strcpy (buf, m ? m->name : "<external>");
  if (*p) {
    strcat (buf, ".");
    strcat (buf, p);
  }
  strcpy (p, buf);
  if (!m || !m->parent) return p;
  return runtime_path (m->parent, p);
}

void
runtime_trace_in (dzn_port_meta_t const* meta, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  strcpy(pbuf, meta->provides.port);
  strcpy(rbuf, meta->requires.port);
  fprintf (stderr, "%s.%s -> %s.%s\n",
           runtime_path (meta->requires.meta, rbuf), e,
           runtime_path (meta->provides.meta, pbuf), e);
}

void
runtime_trace_out (dzn_port_meta_t const* meta, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  strcpy(pbuf, meta->provides.port);
  strcpy(rbuf, meta->requires.port);
  fprintf (stderr, "%s.%s -> %s.%s\n",
           runtime_path (meta->provides.meta, pbuf), e,
           runtime_path (meta->requires.meta, rbuf), e);
}

char*
_bool_to_string (bool b)
{
  return b ? "true" : "false";
}

bool
string_to__bool (char *s)
{
  return !strcmp (s, "true");
}

char*
_int_to_string (int i)
{
  static char buf[sizeof (i) * 2 + 1];
  sprintf (buf, "%d", i);
  return buf;
}

int
string_to__int (char *s)
{
  return atoi (s);
}
