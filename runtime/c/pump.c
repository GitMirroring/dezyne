// -*-comment-start: "//";comment-end:""-*-
// dzn-runtime -- Dezyne runtime library
// Copyright © 2023 Jan Nieuwenhuizen <janneke@gnu.org>
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

#if HAVE_LIBPTH
#include <dzn/pump.h>
#include <stdlib.h>
#include <string.h>

#if DZN_PUMP_DEBUG
#include <stdio.h>
#define debug(...) fprintf (stderr, __VA_ARGS__)
#else
#define debug(...)
#endif

typedef struct port_coroutine port_coroutine;
struct port_coroutine
{
  dzn_interface* port;
  dzn_coroutine coroutine;
};

static port_coroutine*
port_coroutine_create (dzn_interface* port, dzn_coroutine coroutine)
{
  port_coroutine* p = (port_coroutine*)malloc (sizeof (port_coroutine));
  p->port = port;
  p->coroutine = coroutine;
  return p;
}

static int
port_predicate (void* data)
{
  port_coroutine* p = data;
  return p->port == dzn_coroutine_port ();
}

void
dzn_pump_init (dzn_pump* self)
{
  memset (self, 0, sizeof (dzn_pump));
  dzn_coroutine_init ();
}

static dzn_coroutine
pump_create_coroutine (dzn_pump* self, dzn_coroutine_function function)
{
  dzn_coroutine coroutine = dzn_coroutine_create (function, self);
  self->id++;
  debug ("[%ld] pump create coroutine: %ld\n", dzn_coroutine_id (), self->id);
  return coroutine;
}

static void
pump_enqueue (dzn_pump* self, dzn_list** list, void* data)
{
  (void)self;
  *list = dzn_list_append (*list, dzn_list_data (data));
}

static void*
handler (void* data)
{
  dzn_pump* self = (dzn_pump*)data;
  if (!dzn_coroutine_id ())
    dzn_coroutine_set_id (self->id);
  long id = dzn_coroutine_id ();
  debug ("[%ld] handler count=%ld\n", id, self->id);
  dzn_coroutine_yield_to (self->invoking);
  debug ("[%ld] handler: done\n", id);
}

static void
pump_process_released (dzn_pump* self)
{
  long id = dzn_coroutine_id ();
  debug ("[%ld] pump_process_released\n", id);
  while (self->released)
    {
      port_coroutine* p = self->released->data;
      char const* name = p->port->meta.provides.name;
      dzn_coroutine c = p->coroutine;
      free (p);
      dzn_list* rest = self->released->next;
      free (self->released);
      self->released = rest;
      debug ("[%ld] yield to released: %s\n", id, name);
      dzn_coroutine_yield_to (c);
    }
  handler (self);
}

static void*
worker (void* data)
{
  dzn_pump* self = (dzn_pump*)data;
  if (!dzn_coroutine_id ())
    dzn_coroutine_set_id (self->id);

  long id = dzn_coroutine_id ();
  debug ("[%ld] worker count=%ld\n", id, self->id);
  if (self->q)
    {
      dzn_closure* event = self->q->data;
      self->q = dzn_list_delete (self->q, event);
      event->function (event->argument);
    }
  pump_process_released (self);

  debug ("[%ld] worker: done next\n", id);
}

void
dzn_pump_run (dzn_pump* self, dzn_closure* event)
{
  debug ("[%ld] dzn_pump_run\n", dzn_coroutine_id ());
  pump_enqueue (self, &self->q, event);
  self->invoking = dzn_coroutine_self ();
  dzn_coroutine coroutine = pump_create_coroutine (self, worker);
  dzn_coroutine_yield_to (coroutine);
  pump_process_released (self);
}

void
dzn_pump_block (dzn_pump* self, dzn_interface* port)
{
  char const* name = port->meta.provides.name;
  debug ("[%ld] dzn_pump_block: %s\n", dzn_coroutine_id (), name);
  dzn_coroutine_set_port (port);
  port_coroutine* p = dzn_list_find_predicate (self->released, port_predicate);
  if (p)
    {
      debug ("[%ld] dzn_pump_block fall-through: %s\n", dzn_coroutine_id (), name);
      self->released = dzn_list_delete (self->released, p);
      free (p);
      return;
    }
  debug ("[%ld] dzn_pump_block: blocked = %s\n", dzn_coroutine_id (), name);
  p = port_coroutine_create (port, dzn_coroutine_self ());
  pump_enqueue (self, &self->blocked, p);
  dzn_coroutine coroutine = pump_create_coroutine (self, handler);
  dzn_coroutine_yield_to (coroutine);
  dzn_coroutine_set_port (port);
  p = dzn_list_find_predicate (self->blocked, port_predicate);
  if (p)
    {
      self->blocked = dzn_list_delete (self->blocked, p);
      free (p);
    }
  debug ("[%ld] dzn_pump_block continue: %s\n", dzn_coroutine_id (), name);
}

void
dzn_pump_release (dzn_pump* self, dzn_interface* port)
{
  char const* name = port->meta.provides.name;
  debug ("[%ld] dzn_pump_release: %s\n", dzn_coroutine_id (), name);
  dzn_coroutine_set_port (port);
  port_coroutine* p = dzn_list_find_predicate (self->blocked, port_predicate);
  if (!p)
    p = port_coroutine_create (port, dzn_coroutine_self ());
  pump_enqueue (self, &self->released, p);
  debug ("[%ld] dzn_pump_release continue: %s\n", dzn_coroutine_id (), name);
}

////////////////////////////////////////////////////////////////////////////////
// Runtime
void
dzn_port_block (dzn_component* component, dzn_interface* port)
{
  debug ("dzn_port_block: %s\n", port->meta.provides.name);
  component->dzn_info.handling = false;
  dzn_runtime_flush (&component->dzn_info);
  dzn_locator* locator = component->dzn_info.locator;
  dzn_pump* pump = dzn_locator_get (locator, "pump");
  if (pump)
    dzn_pump_block (pump, port);
}

void
dzn_port_release (dzn_component* component, dzn_interface* port)
{
  debug ("dzn_port_release: %s\n", port->meta.provides.name);
  dzn_locator* locator = component->dzn_info.locator;
  dzn_pump* pump = dzn_locator_get (locator, "pump");
  if (pump)
    dzn_pump_release (pump, port);
}
////////////////////////////////////////////////////////////////////////////////
#endif // HAVE_LIBPTH
