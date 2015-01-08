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

#include "Adaptor.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>

typedef enum
{
	State_Idle, State_Active, State_Terminating
} State;

static void run_run(void* self_)
{
	Adaptor* self = (Adaptor*)self_;
	ASD_LOG("Adaptor.run_run");
	if (self->state == State_Idle)
	{
		if (self->count < 2)
		{
			self->console.in.arm(self->console.in.self);
			self->state = State_Active;
		}
		else
		{
		}
	}
	else if (self->state == State_Active)
	{
		{
		}
	}
	else if (self->state == State_Terminating)
	{
		{
		}
	}
}

static void console_detected(void* self_)
{
	Adaptor* self = (Adaptor*)self_;
	ASD_LOG("Adaptor.console_detected");
	if (self->state == State_Idle)
	{
		assert(false);
	}
	else if (self->state == State_Active)
	{
		self->count = self->count + 1;
		(*self->console.in.disarm)(self->console.in.self);
		self->state = State_Terminating;
	}
	else if (self->state == State_Terminating)
	{
		assert(false);
	}
}

static void console_deactivated(void* self_)
{
	Adaptor* self = (Adaptor*)self_;
	ASD_LOG("Adaptor.console_deactivated");
	if (self->state == State_Idle)
	{
		assert(false);
	}
	else if (self->state == State_Active)
	{
		assert(false);
	}
	else if (self->state == State_Terminating)
	{
		if (self->count < 2)
		{
			(*self->console.in.arm)(self->console.in.self);
			self->state = State_Active;
		}
		else
			self->state = State_Idle;
	}
}


void Adaptor_init(Adaptor* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->runtime_inst;
	self->state = State_Idle;
	self->count = 0;
	self->run.in.run = run_run;
	self->run.in.self = self;
	self->console.out.detected = console_detected;
	self->console.out.deactivated = console_deactivated;
	self->console.out.self = self;
}
