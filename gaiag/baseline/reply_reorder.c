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

#include "reply_reorder.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {reply_reorder* self;} args_p_busy;
typedef struct {reply_reorder* self;} args_p_finish;


static void opaque_p_busy(void* args) {
	args_p_busy *a = args;
	void (*f)(void*) = a->self->p->out.busy;
	f(a->self->p);
}

static void opaque_p_finish(void* args) {
	args_p_finish *a = args;
	void (*f)(void*) = a->self->p->out.finish;
	f(a->self->p);
}



static void internal_p_start(void* self_) {
	reply_reorder* self = self_;
	(void)self;
	DZN_LOG("reply_reorder.p_start");
	self->r->in.ping(self->r);
}

static void internal_r_pong(void* self_) {
	reply_reorder* self = self_;
	(void)self;
	DZN_LOG("reply_reorder.r_pong");
	if (self->first) {
		{
			args_p_busy a = {self};
			args_p_busy* p = malloc(sizeof(args_p_busy));
			memcpy (p, &a, sizeof(args_p_busy));
			runtime_defer(self->rt, self, opaque_p_busy, p);
		}
		self->first = !(self->first);
	}
	if (!(self->first)) {
		{
			args_p_finish a = {self};
			args_p_finish* p = malloc(sizeof(args_p_finish));
			memcpy (p, &a, sizeof(args_p_finish));
			runtime_defer(self->rt, self, opaque_p_finish, p);
		}
		self->first = !(self->first);
	}
}

static void opaque_p_start(void* a) {
	typedef struct {reply_reorder* self;} args;
	args* b = a;
	internal_p_start(b->self);
}

static void opaque_r_pong(void* a) {
	typedef struct {reply_reorder* self;} args;
	args* b = a;
	internal_r_pong(b->self);
}

static void p_start(void* self_) {
	reply_reorder* self = ((Provides*)self_)->in.self;
	typedef struct {reply_reorder* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_p_start, a);
}

static void r_pong(void* self_) {
	reply_reorder* self = ((Requires*)self_)->out.self;
	typedef struct {reply_reorder* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_r_pong, a);
}


void reply_reorder_init (reply_reorder* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->first = true;
	self->p = &self->p_;
	self->p->in.start = p_start;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.pong = r_pong;
}
