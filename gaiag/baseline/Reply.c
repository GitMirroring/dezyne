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

#include "Reply.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>

static char const* I_Status_to_string(I_Status v)
{
	switch(v)
	{
		case I_Status_Yes: return "Status_Yes";
		case I_Status_No: return "Status_No";

	}
	return "";
}
static char const* U_Status_to_string(U_Status v)
{
	switch(v)
	{
		case U_Status_Ok: return "Status_Ok";
		case U_Status_Nok: return "Status_Nok";

	}
	return "";
}






typedef struct {int size;int (*f)(Reply*);Reply* self;} args_i_done;




static void helper_i_done(void* args) {
	args_i_done *a = args;
	a->f(a->self);
}







static int i_done(Reply* self) {
	(void)self;
	if (true) {
		int s = self->u->in.what(self->u);
		if (s == U_Status_Ok) {
			self->reply_I_Status = I_Status_Yes;
		}
		else {
			self->reply_I_Status = I_Status_No;
		}
	}
	return self->reply_I_Status;
}

static int call_in_i_done(I* self) {
	runtime_trace_in(&self->in, &self->out, "done");
	args_i_done a = {sizeof(args_i_done), i_done, self->in.self};
	runtime_event(helper_i_done, &a);
	Reply* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, I_Status_to_string (self_->reply_I_Status));
	return self_->reply_I_Status;
}

void Reply_init (Reply* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->dummy = false;
	self->i = &self->i_;
	self->i->in.done = call_in_i_done;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
	self->u = &self->u_;
	self->u->in.name = "";
	self->u->in.self = 0;
	self->u->out.name = "u";
	self->u->out.self = self;
}
