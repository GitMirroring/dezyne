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
#include <string.h>







static void internal_siren_turnon(void* self_) {
	Siren* self = self_;
	(void)self;
	DZN_LOG("Siren.siren_turnon");
	{
	}
}

static void internal_siren_turnoff(void* self_) {
	Siren* self = self_;
	(void)self;
	DZN_LOG("Siren.siren_turnoff");
	{
	}
}

static void opaque_siren_turnon(void* a) {
	typedef struct {Siren* self;} args;
	args* b = a;
	internal_siren_turnon(b->self);
}

static void opaque_siren_turnoff(void* a) {
	typedef struct {Siren* self;} args;
	args* b = a;
	internal_siren_turnoff(b->self);
}

static void siren_turnon(void* self_) {
	Siren* self = ((ISiren*)self_)->in.self;
	typedef struct {Siren* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_siren_turnon, a);
}

static void siren_turnoff(void* self_) {
	Siren* self = ((ISiren*)self_)->in.self;
	typedef struct {Siren* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_siren_turnoff, a);
}


void Siren_init (Siren* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->siren = &self->siren_;
	self->siren->in.turnon = siren_turnon;
	self->siren->in.turnoff = siren_turnoff;
	self->siren->in.self = self;
}
