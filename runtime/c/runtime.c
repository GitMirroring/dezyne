// dzn-runtime -- Dezyne runtime library
// Copyright © 2015, 2016, 2019, 2022, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2015, 2016 Rutger van Beusekom <rutger@dezyne.org>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include <dzn/config.h>
#include <dzn/runtime.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <dzn/mem.h>
#include <dzn/closure.h>
#include <dzn/locator.h>
#include <dzn/queue.h>

void
dzn_runtime_illegal_handler (void)
{
  assert (!"illegal");
}

void
dzn_illegal (dzn_runtime_info const* info)
{
  info->locator->illegal ();
}

void
dzn_runtime_info_init (dzn_runtime_info* info, dzn_locator* locator)
{
  info->locator = locator;
  info->handling = false;
  info->performs_flush = false;
  info->deferred = 0;
  dzn_queue_init (&info->q);
}

static void dzn_runtime_handle_event (dzn_runtime_info* info, void (*event) (void*), void* argument);

void
dzn_runtime_flush (dzn_runtime_info* info)
{
  dzn_queue* q;
#if DZN_DYNAMIC_QUEUES
  dzn_closure* c;
#else /* !DZN_DYNAMIC_QUEUES */
  dzn_closure c;
#endif /* !DZN_DYNAMIC_QUEUES */
  while (info)
    {
      q = &info->q;
      while (dzn_queue_empty (q) == false)
        {
#if DZN_DYNAMIC_QUEUES
          c = dzn_queue_pop (q);
          dzn_runtime_handle_event (info, c->function, c->argument);
          dzn_free (c->argument);
          dzn_free (c);
#else /* !DZN_DYNAMIC_QUEUES */
          c = * (dzn_closure*)dzn_queue_pop (q);
          dzn_runtime_handle_event (info, c.function, c.argument);
#endif /* !DZN_DYNAMIC_QUEUES */
        }
      if (info->deferred)
        {
          dzn_runtime_info* tgt = info->deferred;
          info->deferred = 0;
          if (tgt && !tgt->handling)
            info = tgt;
        }
      else
        break;
    }
}

void
dzn_runtime_defer (void* vsrc, void* vtgt, void (*event) (void*), void* argument)
{
#if DZN_DYNAMIC_QUEUES
  dzn_closure *c;
#else /* !DZN_DYNAMIC_QUEUES */
  dzn_closure c;
#endif /* !DZN_DYNAMIC_QUEUES */
  dzn_arguments *a;
  dzn_component* csrc = vsrc;
  dzn_component* ctgt = vtgt;
  dzn_runtime_info* src = csrc ? &csrc->dzn_info : 0;
  dzn_runtime_info* tgt = ctgt ? &ctgt->dzn_info : 0;
  if (!(src && src->performs_flush) && !tgt->handling)
    dzn_runtime_handle_event (tgt, event, argument);
  else
    {
#if DZN_DYNAMIC_QUEUES
      c = (dzn_closure*) dzn_malloc (sizeof (dzn_closure));
      c->function = event;
      a = argument;
      c->argument = dzn_malloc ((size_t)a->size);
      memcpy (c->argument, a, (size_t)a->size);
      dzn_queue_push (&tgt->q, c);
#else /* !DZN_DYNAMIC_QUEUES */
      c.func = event;
      a = argument;
      assert (a->size <= DZN_MAX_ARGUMENT_SIZE);
      memcpy (&c.argument, a, (size_t)a->size);
      dzn_queue_push (&tgt->q, &c);
#endif /* !DZN_DYNAMIC_QUEUES */
      if (src)
        src->deferred = tgt;
    }
}

static void
dzn_runtime_handle_event (dzn_runtime_info* info, void (*event) (void*), void* argument)
{
  dzn_runtime_start (info);
  event (argument);
  dzn_runtime_finish (info);
}

void
dzn_runtime_event (void (*event) (void*), void* argument)
{
  dzn_arguments* a = argument;
  dzn_component* c = a->self;
  dzn_runtime_handle_event (&c->dzn_info, event, argument);
}

void
dzn_runtime_start (dzn_runtime_info* info)
{
  if (!info->handling)
    info->handling = true;
  else
    assert (!"component already handling an event");
}

void
dzn_runtime_finish (dzn_runtime_info* info)
{
  info->handling = false;
  dzn_runtime_flush (info);
}

#if DZN_TRACING
char*
dzn_runtime_path (dzn_meta const* m, char* p)
{
  char buf[1024] = "";
  strcpy (buf, m ? m->name : "<external>");

  if (*p != (char)0)
    {
      strcat (buf, ".");
      strcat (buf, p);
    }
  strcpy (p, buf);

  return (!m || !m->parent) ? p : dzn_runtime_path (m->parent, p);
}

void
dzn_runtime_trace (dzn_port_meta const* meta, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  strcpy (pbuf, meta->provides.name);
  strcpy (rbuf, meta->requires.name);
  fprintf (stderr, "%s.%s -> %s.%s\n",
           dzn_runtime_path (meta->requires.meta, rbuf), e,
           dzn_runtime_path (meta->provides.meta, pbuf), e);
}

void
dzn_runtime_trace_out (dzn_port_meta const* meta, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  strcpy (pbuf, meta->provides.name);
  strcpy (rbuf, meta->requires.name);
  fprintf (stderr, "%s.%s <- %s.%s\n",
           dzn_runtime_path (meta->requires.meta, rbuf), e,
           dzn_runtime_path (meta->provides.meta, pbuf), e);
}

void
dzn_runtime_trace_qin (dzn_port_meta const* meta, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  if (!meta->requires.meta)
    {
      dzn_runtime_trace_out (meta, e);
      return;
    }
  strcpy (pbuf, meta->provides.name);
  strcpy (rbuf, meta->requires.name);
  fprintf (stderr, "%s.%s <- %s.%s\n",
           dzn_runtime_path (meta->requires.meta, rbuf), "<q>",
           dzn_runtime_path (meta->provides.meta, pbuf), e);
}

void
dzn_runtime_trace_qout (dzn_port_meta const* meta, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  if (!meta->requires.meta)
    return;
  strcpy (pbuf, meta->provides.name);
  strcpy (rbuf, meta->requires.name);
  fprintf (stderr, "%s.%s <- %s.%s\n",
           dzn_runtime_path (meta->requires.meta, rbuf), e,
           dzn_runtime_path (meta->provides.meta, pbuf), "<q>");
}

char*
dzn_bool_to_string (bool b)
{
  char* return_string;
  if (b == 1)
    return_string = "true";
  else
    return_string = "false";
  return return_string;
}

bool
dzn_string_to__bool (char *s)
{
  size_t length;
  bool reply;
  length = strlen ("false");
  reply = (bool) strncmp (s, "false", length);
  return reply;
}

char*
dzn_int_to_string (int i)
{
  static char buffy[ (size_t) ((sizeof (i) * 2) + 1)];
  sprintf (buffy, "%d", i);
  return buffy;
}

int
dzn_string_to__int (char* s)
{
  char *endptr;
  long int val = strtol (s,&endptr,0);
  return (endptr != s) ? (int) val : INT_MAX;
}

#endif /* !DZN_TRACING */
