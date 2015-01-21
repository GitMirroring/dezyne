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
#include <string.h>

typedef enum {
	Alarm_States_Disarmed, Alarm_States_Armed, Alarm_States_Triggered, Alarm_States_Disarming
} Alarm_States;


typedef struct {Alarm* self;} args_console_detected;
typedef struct {Alarm* self;} args_console_deactivated;


static void opaque_console_detected(void* args) {
	args_console_detected *a = args;
	void (*f)(void*) = a->self->console->out.detected;
	f(a->self->console);
}

static void opaque_console_deactivated(void* args) {
	args_console_deactivated *a = args;
	void (*f)(void*) = a->self->console->out.deactivated;
	f(a->self->console);
}



static void internal_console_arm(void* self_) {
	Alarm* self = self_;
	(void)self;
	DZN_LOG("Alarm.console_arm");
	if (self->state == Alarm_States_Disarmed) {
		self->sensor->in.enable(self->sensor);
		self->state = Alarm_States_Armed;
	}
	else if (self->state == Alarm_States_Armed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Disarming) {
		assert(false);
	}
	else if (self->state == Alarm_States_Triggered) {
		assert(false);
	}
}

static void internal_console_disarm(void* self_) {
	Alarm* self = self_;
	(void)self;
	DZN_LOG("Alarm.console_disarm");
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		self->sensor->in.disable(self->sensor);
		self->state = Alarm_States_Disarming;
	}
	else if (self->state == Alarm_States_Disarming) {
		assert(false);
	}
	else if (self->state == Alarm_States_Triggered) {
		self->sensor->in.disable(self->sensor);
		self->siren->in.turnoff(self->siren);
		self->sounding = false;
		self->state = Alarm_States_Disarming;
	}
}

static void internal_sensor_triggered(void* self_) {
	Alarm* self = self_;
	(void)self;
	DZN_LOG("Alarm.sensor_triggered");
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		{
			args_console_detected a = {self};
			args_console_detected* p = malloc(sizeof(args_console_detected));
			memcpy (p, &a, sizeof(args_console_detected));
			runtime_defer(self->rt, self, opaque_console_detected, p);
		}
		self->siren->in.turnon(self->siren);
		self->sounding = true;
		self->state = Alarm_States_Triggered;
	}
	else if (self->state == Alarm_States_Disarming) {
		{
		}
	}
	else if (self->state == Alarm_States_Triggered) {
		assert(false);
	}
}

static void internal_sensor_disabled(void* self_) {
	Alarm* self = self_;
	(void)self;
	DZN_LOG("Alarm.sensor_disabled");
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Disarming) {
		if (self->sounding) {
			{
				args_console_deactivated a = {self};
				args_console_deactivated* p = malloc(sizeof(args_console_deactivated));
				memcpy (p, &a, sizeof(args_console_deactivated));
				runtime_defer(self->rt, self, opaque_console_deactivated, p);
			}
			self->siren->in.turnoff(self->siren);
			self->state = Alarm_States_Disarmed;
			self->sounding = false;
		}
		else {
			{
				args_console_deactivated a = {self};
				args_console_deactivated* p = malloc(sizeof(args_console_deactivated));
				memcpy (p, &a, sizeof(args_console_deactivated));
				runtime_defer(self->rt, self, opaque_console_deactivated, p);
			}
			self->state = Alarm_States_Disarmed;
		}
	}
	else if (self->state == Alarm_States_Triggered) {
		assert(false);
	}
}

static void opaque_console_arm(void* a) {
	typedef struct {Alarm* self;} args;
	args* b = a;
	internal_console_arm(b->self);
}

static void opaque_console_disarm(void* a) {
	typedef struct {Alarm* self;} args;
	args* b = a;
	internal_console_disarm(b->self);
}

static void opaque_sensor_triggered(void* a) {
	typedef struct {Alarm* self;} args;
	args* b = a;
	internal_sensor_triggered(b->self);
}

static void opaque_sensor_disabled(void* a) {
	typedef struct {Alarm* self;} args;
	args* b = a;
	internal_sensor_disabled(b->self);
}

static void console_arm(void* self_) {
	Alarm* self = ((IConsole*)self_)->in.self;
	typedef struct {Alarm* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_console_arm, a);
}

static void console_disarm(void* self_) {
	Alarm* self = ((IConsole*)self_)->in.self;
	typedef struct {Alarm* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_console_disarm, a);
}

static void sensor_triggered(void* self_) {
	Alarm* self = ((ISensor*)self_)->out.self;
	typedef struct {Alarm* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_sensor_triggered, a);
}

static void sensor_disabled(void* self_) {
	Alarm* self = ((ISensor*)self_)->out.self;
	typedef struct {Alarm* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_sensor_disabled, a);
}


void Alarm_init (Alarm* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->state = Alarm_States_Disarmed;
	self->sounding = false;
	self->console = &self->console_;
	self->console->in.arm = console_arm;
	self->console->in.disarm = console_disarm;
	self->console->in.self = self;
	self->sensor = &self->sensor_;
	self->sensor->out.self = self;
	self->sensor->out.triggered = sensor_triggered;
	self->sensor->out.disabled = sensor_disabled;
	self->siren = &self->siren_;
	self->siren->out.self = self;
}
