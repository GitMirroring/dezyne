// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Alarm.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>

typedef enum {
	Alarm_States_Disarmed, Alarm_States_Armed, Alarm_States_Triggered, Alarm_States_Disarming
} Alarm_States;


typedef struct {int size;void (*f)(IConsole*);Alarm* self;} args_console_detected;
typedef struct {int size;void (*f)(IConsole*);Alarm* self;} args_console_deactivated;


typedef struct {int size;void (*f)(Alarm*);Alarm* self;} args_console_arm;
typedef struct {int size;void (*f)(Alarm*);Alarm* self;} args_console_disarm;
typedef struct {int size;void (*f)(Alarm*);Alarm* self;} args_sensor_triggered;
typedef struct {int size;void (*f)(Alarm*);Alarm* self;} args_sensor_disabled;


static void helper_console_detected(void* args) {
	args_console_detected *a = args;
	a->f(a->self->console);
}

static void helper_console_deactivated(void* args) {
	args_console_deactivated *a = args;
	a->f(a->self->console);
}



static void helper_console_arm(void* args) {
	args_console_arm *a = args;
	a->f(a->self);
}

static void helper_console_disarm(void* args) {
	args_console_disarm *a = args;
	a->f(a->self);
}

static void helper_sensor_triggered(void* args) {
	args_sensor_triggered *a = args;
	a->f(a->self);
}

static void helper_sensor_disabled(void* args) {
	args_sensor_disabled *a = args;
	a->f(a->self);
}







static void console_arm(Alarm* self) {
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

static void console_disarm(Alarm* self) {
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

static void sensor_triggered(Alarm* self) {
	(void)self;
	DZN_LOG("Alarm.sensor_triggered");
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		{
			args_console_detected a = {sizeof(args_console_detected), self->console->out.detected, self};
			runtime_defer(self->rt, self, helper_console_detected, &a);
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

static void sensor_disabled(Alarm* self) {
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
				args_console_deactivated a = {sizeof(args_console_deactivated), self->console->out.deactivated, self};
				runtime_defer(self->rt, self, helper_console_deactivated, &a);
			}
			self->siren->in.turnoff(self->siren);
			self->state = Alarm_States_Disarmed;
			self->sounding = false;
		}
		else {
			{
				args_console_deactivated a = {sizeof(args_console_deactivated), self->console->out.deactivated, self};
				runtime_defer(self->rt, self, helper_console_deactivated, &a);
			}
			self->state = Alarm_States_Disarmed;
		}
	}
	else if (self->state == Alarm_States_Triggered) {
		assert(false);
	}
}

static void callback_console_arm(IConsole* self) {
	args_console_arm a = {sizeof(args_console_arm), console_arm, self->in.self};
	runtime_event(helper_console_arm, &a);
}

static void callback_console_disarm(IConsole* self) {
	args_console_disarm a = {sizeof(args_console_disarm), console_disarm, self->in.self};
	runtime_event(helper_console_disarm, &a);
}

static void callback_sensor_triggered(ISensor* self) {
	args_sensor_triggered a = {sizeof(args_sensor_triggered), sensor_triggered, self->out.self};
	runtime_event(helper_sensor_triggered, &a);
}

static void callback_sensor_disabled(ISensor* self) {
	args_sensor_disabled a = {sizeof(args_sensor_disabled), sensor_disabled, self->out.self};
	runtime_event(helper_sensor_disabled, &a);
}


void Alarm_init (Alarm* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->state = Alarm_States_Disarmed;
	self->sounding = false;
	self->console = &self->console_;
	self->console->in.arm = callback_console_arm;
	self->console->in.disarm = callback_console_disarm;
	self->console->in.self = self;
	self->sensor = &self->sensor_;
	self->sensor->out.self = self;
	self->sensor->out.triggered = callback_sensor_triggered;
	self->sensor->out.disabled = callback_sensor_disabled;
	self->siren = &self->siren_;
	self->siren->out.self = self;
}
