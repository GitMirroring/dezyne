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

#include "reply_reorder.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(Provides*);reply_reorder* self;} args_p_busy;
typedef struct {int size;void (*f)(Provides*);reply_reorder* self;} args_p_finish;


typedef struct {int size;void (*f)(reply_reorder*);reply_reorder* self;} args_p_start;
typedef struct {int size;void (*f)(reply_reorder*);reply_reorder* self;} args_r_pong;


static void helper_p_busy(void* args) {
	args_p_busy *a = args;
	a->f(a->self->p);
}

static void helper_p_finish(void* args) {
	args_p_finish *a = args;
	a->f(a->self->p);
}



static void helper_p_start(void* args) {
	args_p_start *a = args;
	a->f(a->self);
}

static void helper_r_pong(void* args) {
	args_r_pong *a = args;
	a->f(a->self);
}







static void p_start(reply_reorder* self) {
	(void)self;
	DZN_LOG("reply_reorder.p_start");
	{
		self->r->in.ping(self->r);
	}
}

static void r_pong(reply_reorder* self) {
	(void)self;
	DZN_LOG("reply_reorder.r_pong");
	if (self->first) {
		{
			args_p_busy a = {sizeof(args_p_busy), self->p->out.busy, self};
			runtime_defer(&self->sub, helper_p_busy, &a);
		}
		self->first = !(self->first);
	}
	else if (!(self->first)) {
		{
			args_p_finish a = {sizeof(args_p_finish), self->p->out.finish, self};
			runtime_defer(&self->sub, helper_p_finish, &a);
		}
		self->first = !(self->first);
	}
}

static void callback_p_start(Provides* self) {
	args_p_start a = {sizeof(args_p_start), p_start, self->in.self};
	runtime_event(helper_p_start, &a);
}

static void callback_r_pong(Requires* self) {
	args_r_pong a = {sizeof(args_r_pong), r_pong, self->out.self};
	runtime_event(helper_r_pong, &a);
}


void reply_reorder_init (reply_reorder* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	self->first = true;
	self->p = &self->p_;
	self->p->in.start = callback_p_start;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.pong = callback_r_pong;
}
