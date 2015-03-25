// Dezyne --- Dezyne command line tools
//
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

#include "bottom.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(ibottom*);bottom* self;} args_b_f;


typedef struct {int size;void (*f)(bottom*);bottom* self;} args_b_e;


static void helper_b_f(void* args) {
	args_b_f *a = args;
	a->f(a->self->b);
}



static void helper_b_e(void* args) {
	args_b_e *a = args;
	a->f(a->self);
}







static void b_e(bottom* self) {
	(void)self;
	self->b->out.f(self->b);
}

static void call_in_b_e(ibottom* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_b_e a = {sizeof(args_b_e), b_e, self->in.self};
	runtime_event(helper_b_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void bottom_init (bottom* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));

	self->b = &self->b_;
	self->b->in.e = call_in_b_e;
	self->b->in.name = "b";
	self->b->in.self = self;
}
