// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
#include <stdlib.h>
#include <string.h>



typedef struct {Sensor* self;} args_sensor_triggered;
typedef struct {Sensor* self;} args_sensor_disabled;


static void opaque_sensor_triggered(void* args) {
	args_sensor_triggered *a = args;
	void (*f)(void*) = a->self->sensor->out.triggered;
	f(a->self->sensor);
}

static void opaque_sensor_disabled(void* args) {
	args_sensor_disabled *a = args;
	void (*f)(void*) = a->self->sensor->out.disabled;
	f(a->self->sensor);
}



static void internal_sensor_enable(void* self_) {
	Sensor* self = self_;
	(void)self;
	DZN_LOG("Sensor.sensor_enable");
	{
	}
}

static void internal_sensor_disable(void* self_) {
	Sensor* self = self_;
	(void)self;
	DZN_LOG("Sensor.sensor_disable");
	{
	}
}

static void opaque_sensor_enable(void* a) {
	typedef struct {Sensor* self;} args;
	args* b = a;
	internal_sensor_enable(b->self);
}

static void opaque_sensor_disable(void* a) {
	typedef struct {Sensor* self;} args;
	args* b = a;
	internal_sensor_disable(b->self);
}

static void sensor_enable(void* self_) {
	Sensor* self = ((ISensor*)self_)->in.self;
	typedef struct {Sensor* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_sensor_enable, a);
}

static void sensor_disable(void* self_) {
	Sensor* self = ((ISensor*)self_)->in.self;
	typedef struct {Sensor* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_sensor_disable, a);
}


void Sensor_init (Sensor* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->sensor = &self->sensor_;
	self->sensor->in.enable = sensor_enable;
	self->sensor->in.disable = sensor_disable;
	self->sensor->in.self = self;
}
