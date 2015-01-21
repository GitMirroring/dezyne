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

#include "enum_collision.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>







static int internal_i_foo(void* self_) {
	enum_collision* self = self_;
	(void)self;
	DZN_LOG("enum_collision.i_foo");
	self->reply_ienum_collision_Retval1 = ienum_collision_Retval1_OK;
	return self->reply_ienum_collision_Retval1;
}

static int internal_i_bar(void* self_) {
	enum_collision* self = self_;
	(void)self;
	DZN_LOG("enum_collision.i_bar");
	self->reply_ienum_collision_Retval2 = ienum_collision_Retval2_NOK;
	return self->reply_ienum_collision_Retval2;
}

static int opaque_i_foo(void* a) {
	typedef struct {enum_collision* self;} args;
	args* b = a;
	internal_i_foo(b->self);
	return b->self->reply_ienum_collision_Retval1;
}

static int opaque_i_bar(void* a) {
	typedef struct {enum_collision* self;} args;
	args* b = a;
	internal_i_bar(b->self);
	return b->self->reply_ienum_collision_Retval2;
}

static int i_foo(void* self_) {
	enum_collision* self = ((ienum_collision*)self_)->in.self;
	typedef struct {enum_collision* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_foo, a);
	return self->reply_ienum_collision_Retval1;
}

static int i_bar(void* self_) {
	enum_collision* self = ((ienum_collision*)self_)->in.self;
	typedef struct {enum_collision* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_bar, a);
	return self->reply_ienum_collision_Retval2;
}


void enum_collision_init (enum_collision* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->i = &self->i_;
	self->i->in.foo = i_foo;
	self->i->in.bar = i_bar;
	self->i->in.self = self;
}
