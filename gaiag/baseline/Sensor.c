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

#include "Sensor.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(ISensor*);Sensor* self;} args_sensor_triggered;
typedef struct {int size;void (*f)(ISensor*);Sensor* self;} args_sensor_disabled;


typedef struct {int size;void (*f)(Sensor*);Sensor* self;} args_sensor_enable;
typedef struct {int size;void (*f)(Sensor*);Sensor* self;} args_sensor_disable;


static void helper_sensor_triggered(void* args) {
	args_sensor_triggered *a = args;
	a->f(a->self->sensor);
}

static void helper_sensor_disabled(void* args) {
	args_sensor_disabled *a = args;
	a->f(a->self->sensor);
}



static void helper_sensor_enable(void* args) {
	args_sensor_enable *a = args;
	a->f(a->self);
}

static void helper_sensor_disable(void* args) {
	args_sensor_disable *a = args;
	a->f(a->self);
}







static void sensor_enable(Sensor* self) {
	(void)self;
	{
	}
}

static void sensor_disable(Sensor* self) {
	(void)self;
	{
	}
}

static void call_in_sensor_enable(ISensor* self) {
	runtime_trace_in(&self->in, &self->out, "enable");
	args_sensor_enable a = {sizeof(args_sensor_enable), sensor_enable, self->in.self};
	runtime_event(helper_sensor_enable, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_sensor_disable(ISensor* self) {
	runtime_trace_in(&self->in, &self->out, "disable");
	args_sensor_disable a = {sizeof(args_sensor_disable), sensor_disable, self->in.self};
	runtime_event(helper_sensor_disable, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void Sensor_init (Sensor* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));

	self->sensor = &self->sensor_;
	self->sensor->in.enable = call_in_sensor_enable;
	self->sensor->in.disable = call_in_sensor_disable;
	self->sensor->in.name = "sensor";
	self->sensor->in.self = self;
}
