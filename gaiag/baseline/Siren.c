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

#include "Siren.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>

typedef enum {
	States_Off, States_On
} States;

void siren_turnon(void* self_)
{
	Siren* self = (Siren*)(self_);
	ASD_LOG("Siren.siren_turnon");
	if (self->state == States_Off)
	{
		self->state = States_On;
	}
	else if (self->state == States_On)
	{
		assert(false);
	}
}

void siren_turnoff(void* self_)
{
	Siren* self = (Siren*)(self_);
	ASD_LOG("Siren.siren_turnoff");
	if (self->state == States_Off)
	{
		assert(false);
	}
	else if (self->state == States_On)
	{
		self->state = States_Off;
	}
}

void Siren_init(Siren* self, locator* dezyne_locator) {
	self->state = States_Off;
	self->siren.in.turnon = siren_turnon;
	self->siren.in.turnoff = siren_turnoff;
	self->siren.in.self = self;
}
