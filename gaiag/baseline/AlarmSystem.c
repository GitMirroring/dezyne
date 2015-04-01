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

#include <string.h>

#define CONNECT(provided, required)\
{\
	provided->out = required->out;\
	required->in = provided->in;\
}

void AlarmSystem_init(AlarmSystem *self, locator* dezyne_locator, dzn_meta_t* dzn_meta) {
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	dzn_meta_t dzn_m_alarm = {"alarm", self};
	Alarm_init(&self->alarm, dezyne_locator, &dzn_m_alarm);
	dzn_meta_t dzn_m_sensor = {"sensor", self};
	Sensor_init(&self->sensor, dezyne_locator, &dzn_m_sensor);
	dzn_meta_t dzn_m_siren = {"siren", self};
	Siren_init(&self->siren, dezyne_locator, &dzn_m_siren);
	self->console = self->alarm.console;
	CONNECT(self->sensor.sensor, self->alarm.sensor);
	CONNECT(self->siren.siren, self->alarm.siren);
}
