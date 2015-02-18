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

#include "Reply4.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>

typedef enum {
	Reply4_Status_Yes, Reply4_Status_No
} Reply4_Status;




typedef struct {int size;int (*f)(Reply4*);Reply4* self;} args_i_done;




static void helper_i_done(void* args) {
	args_i_done *a = args;
	a->f(a->self);
}



static int fun(Reply4* self);
static int fun_arg(Reply4* self, int s);


static int fun(Reply4* self) {
	(void)self;
	return Reply4_Status_Yes;
}

static int fun_arg(Reply4* self, int s) {
	(void)self;
	return s;
}


static int i_done(Reply4* self) {
	(void)self;
	DZN_LOG("Reply4.i_done");
	if (true) {
		int s = self->u->in.what(self->u);
		s = self->u->in.what(self->u);
		if (s == U_Status_Ok) {
			int v = fun (self);
			if (v == Reply4_Status_Yes) self->reply_I_Status = I_Status_Yes;
			else self->reply_I_Status = I_Status_No;
		}
		else {
			int v = fun_arg(self, Reply4_Status_No);
			if (v == Reply4_Status_Yes) self->reply_I_Status = I_Status_Yes;
			else self->reply_I_Status = I_Status_No;
		}
	}
	return self->reply_I_Status;
}

static int callback_i_done(I* self) {
	args_i_done a = {sizeof(args_i_done), i_done, self->in.self};
	runtime_event(helper_i_done, &a);
	Reply4* self_ = self->in.self;
	return self_->reply_I_Status;
}


void Reply4_init (Reply4* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	self->dummy = false;
	self->i = &self->i_;
	self->i->in.done = callback_i_done;
	self->i->in.self = self;
	self->u = &self->u_;
	self->u->out.self = self;
}
