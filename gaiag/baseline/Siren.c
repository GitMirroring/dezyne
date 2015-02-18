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

#include "Siren.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>





typedef struct {int size;void (*f)(Siren*);Siren* self;} args_siren_turnon;
typedef struct {int size;void (*f)(Siren*);Siren* self;} args_siren_turnoff;




static void helper_siren_turnon(void* args) {
	args_siren_turnon *a = args;
	a->f(a->self);
}

static void helper_siren_turnoff(void* args) {
	args_siren_turnoff *a = args;
	a->f(a->self);
}







static void siren_turnon(Siren* self) {
	(void)self;
	DZN_LOG("Siren.siren_turnon");
	{
	}
}

static void siren_turnoff(Siren* self) {
	(void)self;
	DZN_LOG("Siren.siren_turnoff");
	{
	}
}

static void callback_siren_turnon(ISiren* self) {
	args_siren_turnon a = {sizeof(args_siren_turnon), siren_turnon, self->in.self};
	runtime_event(helper_siren_turnon, &a);
}

static void callback_siren_turnoff(ISiren* self) {
	args_siren_turnoff a = {sizeof(args_siren_turnoff), siren_turnoff, self->in.self};
	runtime_event(helper_siren_turnoff, &a);
}


void Siren_init (Siren* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);

	self->siren = &self->siren_;
	self->siren->in.turnon = callback_siren_turnon;
	self->siren->in.turnoff = callback_siren_turnoff;
	self->siren->in.self = self;
}
