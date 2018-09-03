// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015, 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

#include <dzn/config.h>
#include <dzn/runtime.h>

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <dzn/mem.h>
#include <dzn/closure.h>
#include <dzn/locator.h>
#include <dzn/queue.h>
#include <dzn/runloc.h>


void
runtime_illegal_handler(void)
{
  assert(!"illegal");
}


void dzn_illegal(const runtime_info* info)
{
  info->lc->illegal();
}


void
runtime_info_init (runtime_info* info, locator* loc)
{
  info->lc = loc;
  info->handling = false;
  info->performs_flush = false;
  info->deferred = 0;
  queue_init(&info->q);
}

static void runtime_handle_event (runtime_info* info, void (*event)(void* void_args), void* args);

void
runtime_flush (runtime_info* info)
{
  queue* q;
#if DZN_DYNAMIC_QUEUES
  dzn_closure* c;
#else /* !DZN_DYNAMIC_QUEUES */
  dzn_closure c;
#endif /* !DZN_DYNAMIC_QUEUES */
  while (info != 0)
  {
  q = &info->q;
  while (queue_empty (q)== false)
  {
#if DZN_DYNAMIC_QUEUES
    c = queue_pop (q);
    runtime_handle_event (info, c->func, c->args);
    dzn_free (c->args);
    dzn_free (c);
#else /* !DZN_DYNAMIC_QUEUES */
    c = *(dzn_closure*)queue_pop (q);
    runtime_handle_event (info, c.func, c.args);
#endif /* !DZN_DYNAMIC_QUEUES */
  }
  if (info->deferred != 0)
  {
    runtime_info* tgt = info->deferred;
    info->deferred = 0;
    if ((tgt != 0) && (tgt->handling == 0u))
    {
      info = tgt;
    }
  }
  else
    {
      break;
    }

  }
}

void
runtime_defer (void* vsrc, void* vtgt, void (*event)(void* void_args), void* args)
{
#if DZN_DYNAMIC_QUEUES
  dzn_closure *c;
#else /* !DZN_DYNAMIC_QUEUES */
  dzn_closure c;
#endif /* !DZN_DYNAMIC_QUEUES */
  arguments *a;
  component* csrc = vsrc;
  component* ctgt = vtgt;
  runtime_info* src = (csrc!=0)?&csrc->dzn_info:0;
  runtime_info* tgt = (ctgt!=0)?&ctgt->dzn_info:0;
  if ((!((src != 0u) && (src->performs_flush != 0u))) && (tgt->handling==0u))
  {
    runtime_handle_event (tgt, event, args);
  }
  else
  {
#if DZN_DYNAMIC_QUEUES
      c = (dzn_closure*) dzn_malloc (sizeof (dzn_closure));
      c->func = event;
      a = args;
      c->args = dzn_malloc ((size_t)a->size);
      memcpy (c->args, a,(size_t)a->size);
      queue_push (&tgt->q, c);
#else /* !DZN_DYNAMIC_QUEUES */
      c.func = event;
      a = args;
      assert(a->size <= DZN_MAX_ARGS_SIZE);
      memcpy(&c.args, a, (size_t)a->size);
      queue_push (&tgt->q, &c);
#endif /* !DZN_DYNAMIC_QUEUES */
      if (src != 0u)
      {
        src->deferred = tgt;
      }
  }
}

static void
runtime_handle_event (runtime_info* info, void (*event)(void* void_args), void* args)
{
  runtime_start(info);
  event(args);
  runtime_finish(info);
}

void
runtime_event (void (*event)(void* void_args), void* args)
{
  arguments* a = args;
  component* c = a->self;
  runtime_handle_event (&c->dzn_info, event, args);
}

void
runtime_start (runtime_info* info)
{
  if (info->handling==0u)
  {
    info->handling = true;
  }
  else
  {
    assert(!"component already handling an event");
  }
}

void
runtime_finish (runtime_info* info)
{
    info->handling = false;
    runtime_flush (info);
}

#if DZN_TRACING
char*
runtime_path (dzn_meta const* m, char* p)
{
  char buf[1024] = "";
  strcpy (buf, (m!=0) ? m->name : "<external>");

  if (*p != (char)0) {
    strcat (buf, ".");
    strcat (buf, p);
  }
  strcpy (p, buf);

  return ((m==0) || (m->parent==0)) ? p : runtime_path(m->parent, p);
}

void
runtime_trace_in (dzn_port_meta const* mt, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  strcpy(pbuf, mt->provides.port);
  strcpy(rbuf, mt->requires.port);
  fprintf (stderr, "%s.%s -> %s.%s\n",
           runtime_path (mt->requires.meta, rbuf), e,
           runtime_path (mt->provides.meta, pbuf), e);
}

void
runtime_trace_out (dzn_port_meta const* mt, char const* e)
{
  char pbuf[1024] = "";
  char rbuf[1024] = "";
  strcpy(pbuf, mt->provides.port);
  strcpy(rbuf, mt->requires.port);
  fprintf (stderr, "%s.%s -> %s.%s\n",
           runtime_path (mt->provides.meta, pbuf), e,
           runtime_path (mt->requires.meta, rbuf), e);
}

char*
_bool_to_string (bool b)
{
  char* return_string;
  if (b==1u) {return_string = "true";} else {return_string = "false";}
  return return_string;
}

bool
string_to__bool (char *s)
{
  size_t length;
  bool reply;
  length = strlen("false");
  reply = (bool) strncmp(s, "false", length);
  return reply;
}

char*
_int_to_string (int i)
{
  static char buffy[(size_t)((sizeof (i) * 2u) + 1u)];
  sprintf (buffy, "%d", i);
  return buffy;
}

int
string_to__int (char* s)
{
  char *endptr;
  long int val = strtol(s,&endptr,0);
  return (endptr != s) ? (int) val : INT_MIN;
}

#endif /* !DZN_TRACING */
