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
	DZN_LOG("enum_collision.i_foo");
	self->reply_ienum_collision_Retval1 = ienum_collision_Retval1_OK;
	return self->reply_ienum_collision_Retval1;
}

static int i_bar(enum_collision* self) {
	(void)self;
	DZN_LOG("enum_collision.i_bar");
	self->reply_ienum_collision_Retval2 = ienum_collision_Retval2_NOK;
	return self->reply_ienum_collision_Retval2;
}

static int callback_i_foo(ienum_collision* self) {
	args_i_foo a = {sizeof(args_i_foo), i_foo, self->in.self};
	runtime_event(helper_i_foo, &a);
	enum_collision* self_ = self->in.self;
	return self_->reply_ienum_collision_Retval1;
}

static int callback_i_bar(ienum_collision* self) {
	args_i_bar a = {sizeof(args_i_bar), i_bar, self->in.self};
	runtime_event(helper_i_bar, &a);
	enum_collision* self_ = self->in.self;
	return self_->reply_ienum_collision_Retval2;
}


void enum_collision_init (enum_collision* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);

	self->i = &self->i_;
	self->i->in.foo = callback_i_foo;
	self->i->in.bar = callback_i_bar;
	self->i->in.self = self;
}
