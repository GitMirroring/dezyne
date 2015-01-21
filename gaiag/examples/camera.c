// Dezyne --- Dezyne command line tools
//
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
#include "locator.h"

#include "Camera.h"

#include "Hardware.h"

#include <stdio.h>
#include <stdlib.h>

void focus(){printf("Driver.focus\n");}
void image(){printf("Driver.image\n");}
void ready(){printf("Driver.ready\n");}

map hardware;
int cnt = 0;

typedef struct
{
  Hardware* hw;
  int id;
  bool idle;
} hw_tuple;

static char*
hardware_key (void* scope)
{
  static char buf[sizeof (void*) * 2 + 3];
  sprintf (buf, "%p", scope);
  return buf;
}

static hw_tuple*
hardware_get (map* self, void* scope)
{
  void* p = 0;
  map_get (self, hardware_key (scope), &p);
  return p;
}

int serve_interrupt(map_element* elt, void* unused) {
  (void) unused;
  hw_tuple* p = elt->data;
  if(!p->idle) {
    p->idle = true;
    printf("Hardware[%d].interrupt\n", p->id);
    p->hw->port->out.interrupt(p->hw->port);
  }
  return 0;
}

void serve_interrupts() {
  map_iterate(&hardware, serve_interrupt, NULL);
}

int main()
{
  // create runtime infrastructure
  runtime rt;
  runtime_init(&rt);
  locator l;
  locator_init(&l, &rt);

  map_init(&hardware);

  // create camera component
  Camera cam;
  Camera_init(&cam, &l);

  // stub unconnected callback functions from camera component
  cam.control->out.focus = focus;
  cam.control->out.image = image;
  cam.control->out.ready = ready;

  // play the example test trace
  cam.control->in.setup(cam.control);
  serve_interrupts();

  cam.control->in.shoot(cam.control);
  serve_interrupts();
}

void Hardware_port_kick(void* self_) {
  IHardware* self = self_;
  hw_tuple* p = hardware_get(&hardware, self->in.self);
  p->idle = false;
  printf("Hardware[%d].kick\n", p->id);
}
void Hardware_port_cancel(void* self_) {
  IHardware* self = self_;
  hw_tuple* p = hardware_get(&hardware, self->in.self);
  p->idle = true;
  printf("Hardware[%d].cancel\n", p->id);
}

void Hardware_init(Hardware* self, locator* dezyne_locator)
{
  self->rt = dezyne_locator->rt;
  runtime_set(self->rt, self);
  self->port = &self->port_;
  self->port->in.self = self;
  self->port->in.kick = Hardware_port_kick;
  self->port->in.cancel = Hardware_port_cancel;

  hw_tuple* p = malloc (sizeof (hw_tuple));
  p->hw = self;
  p->id = cnt++;
  p->idle = true;
  map_put (&hardware, hardware_key (self), p);
}
