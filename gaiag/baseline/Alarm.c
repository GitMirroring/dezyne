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

#include "Alarm.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>



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
	if (self->state == Alarm_States_Disarmed) {
		{
			self->sensor->in.enable(self->sensor);
			self->state = Alarm_States_Armed;
		}
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
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		{
			self->sensor->in.disable(self->sensor);
			self->state = Alarm_States_Disarming;
		}
	}
	else if (self->state == Alarm_States_Disarming) {
		assert(false);
	}
	else if (self->state == Alarm_States_Triggered) {
		{
			self->sensor->in.disable(self->sensor);
			self->siren->in.turnoff(self->siren);
			self->sounding = false;
			self->state = Alarm_States_Disarming;
		}
	}
}

static void sensor_triggered(Alarm* self) {
	(void)self;
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		{
			self->console->out.detected(self->console);
			self->siren->in.turnon(self->siren);
			self->sounding = true;
			self->state = Alarm_States_Triggered;
		}
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
	if (self->state == Alarm_States_Disarmed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Armed) {
		assert(false);
	}
	else if (self->state == Alarm_States_Disarming && self->sounding) {
		self->console->out.deactivated(self->console);
		self->siren->in.turnoff(self->siren);
		self->state = Alarm_States_Disarmed;
		self->sounding = false;
	}
	else if (self->state == Alarm_States_Disarming && !(self->sounding)) {
		self->console->out.deactivated(self->console);
		self->state = Alarm_States_Disarmed;
	}
	else if (self->state == Alarm_States_Triggered) {
		assert(false);
	}
}

static void call_in_console_arm(IConsole* self) {
	runtime_trace_in(&self->in, &self->out, "arm");
	args_console_arm a = {sizeof(args_console_arm), console_arm, self->in.self};
	runtime_event(helper_console_arm, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_console_disarm(IConsole* self) {
	runtime_trace_in(&self->in, &self->out, "disarm");
	args_console_disarm a = {sizeof(args_console_disarm), console_disarm, self->in.self};
	runtime_event(helper_console_disarm, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_out_sensor_triggered(ISensor* self) {
	runtime_trace_out(&self->in, &self->out, "triggered");
	args_sensor_triggered a = {sizeof(args_sensor_triggered), sensor_triggered, self->out.self};
	component *c = self->out.self;
	runtime_defer(self->in.self, self->out.self, helper_sensor_triggered, &a);
}

static void call_out_sensor_disabled(ISensor* self) {
	runtime_trace_out(&self->in, &self->out, "disabled");
	args_sensor_disabled a = {sizeof(args_sensor_disabled), sensor_disabled, self->out.self};
	component *c = self->out.self;
	runtime_defer(self->in.self, self->out.self, helper_sensor_disabled, &a);
}


void Alarm_init (Alarm* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));
	self->state = Alarm_States_Disarmed;
	self->sounding = false;
	self->console = &self->console_;
	self->console->in.arm = call_in_console_arm;
	self->console->in.disarm = call_in_console_disarm;
	self->console->in.name = "console";
	self->console->in.self = self;
	self->sensor = &self->sensor_;
	self->sensor->out.name = "sensor";
	self->sensor->out.self = self;
	self->sensor->out.triggered = call_out_sensor_triggered;
	self->sensor->out.disabled = call_out_sensor_disabled;
	self->siren = &self->siren_;
	self->siren->out.name = "siren";
	self->siren->out.self = self;
}
