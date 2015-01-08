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

#include "Alarm.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>

typedef enum {
	States_Disarmed, States_Armed, States_Triggered, States_Disarming
} States;

static void console_arm(void* self_) {
	Alarm* self = (Alarm*)(self_);
	ASD_LOG("Alarm.console_arm");
	if (self->state == States_Disarmed) {
		(*self->sensor.in.enable)(self->sensor.in.self);
		self->state = States_Armed;
	}
	else if (self->state == States_Armed) {
		assert(false);
	}
	else if (self->state == States_Disarming) {
		assert(false);
	}
	else if (self->state == States_Triggered) {
		assert(false);
	}
}

static void console_disarm(void* self_) {
	Alarm* self = (Alarm*)(self_);
	ASD_LOG("Alarm.console_disarm");
	if (self->state == States_Disarmed) {
		assert(false);
	}
	else if (self->state == States_Armed) {
		(*self->sensor.in.disable)(self->sensor.in.self);
		self->state = States_Disarming;
	}
	else if (self->state == States_Disarming) {
		assert(false);
	}
	else if (self->state == States_Triggered) {
		(*self->sensor.in.disable)(self->sensor.in.self);
		self->sounding = false;
		self->state = States_Disarming;
	}
}

static void sensor_triggered(void* self_) {
	Alarm* self = (Alarm*)(self_);
	ASD_LOG("Alarm.sensor_triggered");
	if (self->state == States_Disarmed) {
		assert(false);
	}
	else if (self->state == States_Armed) {
		//rt.defer(this, boost::bind(console.out.detected));
		(*self->siren.in.turnon)(self->siren.in.self);
		self->sounding = true;
		self->state = States_Triggered;
	}
	else if (self->state == States_Disarming) {
		assert(false);
	}
	else if (self->state == States_Triggered) {
		assert(false);
	}
}

static void sensor_disabled(void* self_) {
	Alarm* self = (Alarm*)(self_);
	ASD_LOG("Alarm.sensor_disabled");
	if (self->state == States_Disarmed) {
		assert(false);
	}
	else if (self->state == States_Armed) {
		assert(false);
	}
	else if (self->state == States_Disarming) {
		if (self->sounding) {
			//rt.defer(this, boost::bind(console.out.deactivated));
			self->sounding = false;
			self->state = States_Disarmed;
		}
		else {
			//rt.defer(this, boost::bind(console.out.deactivated));
			self->state = States_Disarmed;
		}
	}
	else if (self->state == States_Triggered) {
		assert(false);
	}
}

void Alarm_init(Alarm* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->runtime_inst;
	self->state = States_Disarmed;
	self->sounding = false;
	self->console.in.arm = console_arm;
	self->console.in.disarm = console_disarm;
	self->console.in.self = self;
	self->sensor.out.triggered = sensor_triggered;
	self->sensor.out.disabled = sensor_disabled;
	self->sensor.out.self = self;
}

