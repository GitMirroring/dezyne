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

#include "AlarmSystem.h"

#define CONNECT(provided, required)\
{\
	provided->out = required->out;\
	required->in = provided->in;\
}

void AlarmSystem_init(AlarmSystem *self, locator* dezyne_locator) {
	Alarm_init(&self->alarm, dezyne_locator);
	Sensor_init(&self->sensor, dezyne_locator);
	Siren_init(&self->siren, dezyne_locator);
	self->console = self->alarm.console;
	CONNECT(self->sensor.sensor, self->alarm.sensor);
	CONNECT(self->siren.siren, self->alarm.siren);
}
