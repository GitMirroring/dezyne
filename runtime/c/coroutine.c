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

#include <dzn/coroutine.h>

#if HAVE_LIBPTH

#ifdef DZN_COROUTINE_TEST
#define DZN_COROUTINE_DEBUG 1
#endif

#if DZN_COROUTINE_DEBUG
#include <stdio.h>
#define debug(...) fprintf (stderr, __VA_ARGS__)
#else
#define debug(...)
#endif

static pth_key_t id_key;
static pth_key_t port_key;

int
dzn_coroutine_init ()
{
  if (!pth_init ())
    return -1;
  if (!pth_key_create (&id_key, 0))
    return -1;
  if (!pth_key_create (&port_key, 0))
    return -1;
  if (!dzn_coroutine_set_id (-1))
    return -1;
  return 0;
}

dzn_coroutine
dzn_coroutine_self ()
{
  return (dzn_coroutine)pth_self ();
}

dzn_coroutine
dzn_coroutine_create (dzn_coroutine_function function, void* data)
{
  return pth_spawn (0, function, data);
}

int
dzn_coroutine_yield_to (dzn_coroutine coroutine)
{
  return pth_yield (coroutine);
}

long
dzn_coroutine_id ()
{
  return (long)pth_key_getdata (id_key);
}

int
dzn_coroutine_set_id (long id)
{
  return pth_key_setdata (id_key, (void*)id);
}

dzn_interface*
dzn_coroutine_port ()
{
  return pth_key_getdata (port_key);
}

int
dzn_coroutine_set_port (dzn_interface* port)
{
  return pth_key_setdata (port_key, port);
}

#if DZN_COROUTINE_TEST

#include <string.h>
#define DZN_COROUTINE_MAX 10

typedef struct pump pump;
struct pump
{
  char canary[20];
  long id;
  pth_t coroutines[DZN_COROUTINE_MAX];
};

dzn_coroutine
pump_create_coroutine (pump* self, dzn_coroutine_function function)
{
  if (!self->id)
    dzn_coroutine_init ();
  dzn_coroutine coroutine = dzn_coroutine_create (function, self);
  self->coroutines[self->id++] = coroutine;
  return coroutine;
}

int
pump_get_id (pump* self, dzn_coroutine coroutine)
{
  for (int i = 0; i < self->id; i++)
    if (self->coroutines[i] == coroutine)
      return i;
  return -1;
}

int
pump_yield_to (pump* self, dzn_coroutine coroutine)
{
  (void*) self;
  return dzn_coroutine_yield_to (coroutine);
}

void*
worker (void* data)
{
  debug ("worker, data=%p\n", data);
  dzn_coroutine self = dzn_coroutine_self ();
  pump* pump = data;
  debug (" CANARY=%s\n", pump->canary);

  if (!dzn_coroutine_id ())
    dzn_coroutine_set_id (pump->id);

  //int id = pump_get_id (pump, self);
  long id = dzn_coroutine_id ();
  debug ("WORKER ID: %ld\n", (long)pth_key_getdata (id_key));

  dzn_coroutine* coroutines;
  switch (id)
    {
    case 1:
      {
        debug ("  ONE id=%d\n", id);
        dzn_coroutine coroutine = pump_create_coroutine (pump, worker);
        pump_yield_to (pump, coroutine);
        debug ("  EXIT ONE\n");
        break;
      }
    case 2:
      {
        debug ("  TWO id=%d\n", id);
        dzn_coroutine coroutine = pump_create_coroutine (pump, worker);
        pump_yield_to (pump, coroutine);
        debug ("  EXIT TWO\n");
        break;
      }
    case 3:
      {
        debug ("  THREE id=%d\n", id);
        pump_yield_to (pump, pump->coroutines[0]);
        debug ("  EXIT THREE\n");
        break;
      }
    }
  return 0;
}

int
main ()
{
  int count = 0;
  pump pump;
  memset (&pump, 0, sizeof (pump));
  dzn_coroutine_init ();
  debug ("MAIN ID: %ld\n", dzn_coroutine_id ());
  strcpy (pump.canary, "KANARIE!");
  dzn_coroutine coroutine = pump_create_coroutine (&pump, &worker);
  debug ("created: %p\n", coroutine);
  pump_yield_to (&pump, coroutine);
  debug ("dun\n");
  return 0;
}
#endif // DZN_COROUTINE_TEST
#endif // HAVE_LIBPTH
