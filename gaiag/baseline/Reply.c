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

#include "Reply.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>







static int internal_i_done(void* self_) {
	Reply* self = self_;
	(void)self;
	DZN_LOG("Reply.i_done");
	if (true) {
		int s = self->u->in.what(self->u);
		if (s == U_Status_Ok)
		{
			self->reply_I_Status = I_Status_Yes;
		}
		else
		{
			self->reply_I_Status = I_Status_No;
		}
	}
	return self->reply_I_Status;
}

static int opaque_i_done(void* a) {
	typedef struct {Reply* self;} args;
	args* b = a;
	internal_i_done(b->self);
	return b->self->reply_I_Status;
}

static int i_done(void* self_) {
	Reply* self = ((I*)self_)->in.self;
	typedef struct {Reply* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_done, a);
	return self->reply_I_Status;
}


void Reply_init (Reply* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->dummy = false;
	self->i = &self->i_;
	self->i->in.done = i_done;
	self->i->in.self = self;
	self->u = &self->u_;
	self->u->out.self = self;
}
