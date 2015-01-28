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

#include "Reply5.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>





typedef struct {int size;int (*f)(void*);Reply5* self;} args_i_done;




static void helper_i_done(void* args) {
	args_i_done *a = args;
	a->f(a->self);
}



static int fun(Reply5* self);
static int fun_arg(Reply5* self, int s);


static int fun(Reply5* self) {
	(void)self;
	return I_Status_Yes;
}

static int fun_arg(Reply5* self, int s) {
	(void)self;
	return s;
}


static int i_done(void* self_) {
	Reply5* self = self_;
	(void)self;
	DZN_LOG("Reply5.i_done");
	if (true) {
		int s = self->u->in.what(self->u);
		s = self->u->in.what(self->u);
		if (s == U_Status_Ok) {
			int s = fun (self);
			self->reply_I_Status = s;
		}
		else {
			int s = fun_arg(self, I_Status_No);
			self->reply_I_Status = s;
		}
	}
	return self->reply_I_Status;
}

static int callback_i_done(void* self_) {
	Reply5* self = ((I*)self_)->in.self;
	args_i_done a = {sizeof(args_i_done), i_done, self};
	runtime_event(helper_i_done, &a);
	return self->reply_I_Status;
}


void Reply5_init (Reply5* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->dummy = false;
	self->i = &self->i_;
	self->i->in.done = callback_i_done;
	self->i->in.self = self;
	self->u = &self->u_;
	self->u->out.self = self;
}
