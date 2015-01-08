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

static void sensor_enable(void* self_)
{
	Sensor* self = (Sensor*)(self_);
	ASD_LOG("Sensor.sensor_enable");
	//rt.defer(this, boost::bind(sensor.out.triggered));
	(*self->sensor.out.triggered)(self->sensor.out.self);
}

static void sensor_disable(void* self_)
{
	Sensor* self = (Sensor*)(self_);
	ASD_LOG("Sensor.sensor_disable");
	//rt.defer(this, boost::bind(sensor.out.disabled));
	(*self->sensor.out.disabled)(self->sensor.out.self);
}

void Sensor_init(Sensor* self, locator* dezyne_locator)
{
	self->rt = dezyne_locator->runtime_inst;
	self->sensor.in.enable = sensor_enable;
	self->sensor.in.disable = sensor_disable;
	self->sensor.in.self = self;
}
