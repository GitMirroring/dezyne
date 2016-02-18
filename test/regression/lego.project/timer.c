// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "timer.h"
#include "itimer_impl.h"

#include <dzn/locator.h>
#include <dzn/runtime.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
	dzn_meta_t dzn_meta;
	runtime_info dzn_info;
	itimer port_;
	itimer* port;
	itimer_impl* pimpl;
} timer_help;

typedef struct {int size;void (*f)(itimer*);timer_help* self;} args_port_timeout;


typedef struct {int size;void (*f)(timer_help*,uint32_t);timer_help* self;uint32_t ms;} args_port_create;
typedef struct {int size;void (*f)(timer_help*);timer_help* self;} args_port_cancel;


static void helper_port_timeout(void* args) {
	args_port_timeout *a = args;
	a->f(a->self->port);
}



static void helper_port_create(void* args) {
	args_port_create *a = args;
	a->f(a->self,a->ms);
}

static void helper_port_cancel(void* args) {
	args_port_cancel *a = args;
	a->f(a->self);
}


void timer_impl_create (itimer_impl* self, int ms);

void timer_impl_cancel (itimer_impl* self);

static void port_create(timer_help* self,uint32_t ms) {
	(void)self;
        // fprintf (stderr, "%s\n", __FUNCTION__);
        timer_impl_create (self->pimpl, ms);
}

static void port_cancel(timer_help* self) {
	(void)self;
        //fprintf (stderr, "%s\n", __FUNCTION__);
        timer_impl_cancel (self->pimpl);
}

static void call_in_port_create(itimer* self,uint32_t ms) {
	runtime_trace_in(&self->in, &self->out, "create");
	args_port_create a = {sizeof(args_port_create), port_create, self->in.self,ms};
	runtime_event(helper_port_create, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_port_cancel(itimer* self) {
	runtime_trace_in(&self->in, &self->out, "cancel");
	args_port_cancel a = {sizeof(args_port_cancel), port_cancel, self->in.self};
	runtime_event(helper_port_cancel, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void timer_init (timer* self, locator* dezyne_locator, dzn_meta_t *m) {
	timer_help* help = malloc (sizeof (timer_help));
	runtime_info_init(&help->dzn_info, dezyne_locator);
	memcpy(&help->dzn_meta, m, sizeof(dzn_meta_t));

	help->port = &self->port_;
	help->port->in.create = call_in_port_create;
	help->port->in.cancel = call_in_port_cancel;
	help->port->in.name = "port";
	help->port->in.self = help;
	help->port->out.name = "";
	help->port->out.self = 0;
        self->port = help->port;

        itimer_impl* (*f)(locator* loc) = locator_get (dezyne_locator, "timer.create");
        locator *tmp = locator_clone (dezyne_locator);
        locator_set (tmp, "timer.port", self->port);
        help->pimpl = f (tmp);
}
