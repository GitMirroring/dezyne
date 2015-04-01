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

#include "enum_collision.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>

static char const* ienum_collision_Retval1_to_string(ienum_collision_Retval1 v)
{
	switch(v)
	{
		case ienum_collision_Retval1_OK: return "Retval1_OK";
		case ienum_collision_Retval1_NOK: return "Retval1_NOK";

	}
	return "";
}
static char const* ienum_collision_Retval2_to_string(ienum_collision_Retval2 v)
{
	switch(v)
	{
		case ienum_collision_Retval2_OK: return "Retval2_OK";
		case ienum_collision_Retval2_NOK: return "Retval2_NOK";

	}
	return "";
}






typedef struct {int size;int (*f)(enum_collision*);enum_collision* self;} args_i_foo;
typedef struct {int size;int (*f)(enum_collision*);enum_collision* self;} args_i_bar;




static void helper_i_foo(void* args) {
	args_i_foo *a = args;
	a->f(a->self);
}

static void helper_i_bar(void* args) {
	args_i_bar *a = args;
	a->f(a->self);
}







static int i_foo(enum_collision* self) {
	(void)self;
	self->reply_ienum_collision_Retval1 = ienum_collision_Retval1_OK;
	return self->reply_ienum_collision_Retval1;
}

static int i_bar(enum_collision* self) {
	(void)self;
	self->reply_ienum_collision_Retval2 = ienum_collision_Retval2_NOK;
	return self->reply_ienum_collision_Retval2;
}

static int call_in_i_foo(ienum_collision* self) {
	runtime_trace_in(&self->in, &self->out, "foo");
	args_i_foo a = {sizeof(args_i_foo), i_foo, self->in.self};
	runtime_event(helper_i_foo, &a);
	enum_collision* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, ienum_collision_Retval1_to_string (self_->reply_ienum_collision_Retval1));
	return self_->reply_ienum_collision_Retval1;
}
static int call_in_i_bar(ienum_collision* self) {
	runtime_trace_in(&self->in, &self->out, "bar");
	args_i_bar a = {sizeof(args_i_bar), i_bar, self->in.self};
	runtime_event(helper_i_bar, &a);
	enum_collision* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, ienum_collision_Retval2_to_string (self_->reply_ienum_collision_Retval2));
	return self_->reply_ienum_collision_Retval2;
}

void enum_collision_init (enum_collision* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));

	self->i = &self->i_;
	self->i->in.foo = call_in_i_foo;
	self->i->in.bar = call_in_i_bar;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
}
