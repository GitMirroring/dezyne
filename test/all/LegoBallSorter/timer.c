// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
typedef struct {int size;void (*f)(timer*,Integer);timer_help** self;Integer ms;} args_port_create;
typedef struct {int size;void (*f)(timer*);timer_help* self;} args_port_cancel;


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

static void port_create(timer_help* self, uint32_t ms) {
	(void)self;
        // fprintf (stderr, "%s\n", __FUNCTION__);
        timer_impl_create (self->pimpl, ms);
}

static void port_cancel(timer_help* self) {
	(void)self;
        //fprintf (stderr, "%s\n", __FUNCTION__);
        timer_impl_cancel (self->pimpl);
}

static void call_in_port_create(itimer* port,Integer ms) {
	runtime_trace_in(&port->meta, "create");
	args_port_create a = {sizeof(args_port_create), port_create, port->meta.provides.address,ms};
	runtime_event(helper_port_create, &a);
	runtime_trace_out(&port->meta, "return");
}
static void call_in_port_cancel(itimer* port) {
	runtime_trace_in(&port->meta, "cancel");
	args_port_cancel a = {sizeof(args_port_cancel), port_cancel, port->meta.provides.address};
	runtime_event(helper_port_cancel, &a);
	runtime_trace_out(&port->meta, "return");
}

void timer_init (timer* self, locator* dezyne_locator, dzn_meta_t *m) {
	timer_help* help = malloc (sizeof (timer_help));
	runtime_info_init(&help->dzn_info, dezyne_locator);
	memcpy(&help->dzn_meta, m, sizeof(dzn_meta_t));

	help->port = &self->port_;
	help->port->in.create = call_in_port_create;
	help->port->in.cancel = call_in_port_cancel;
	help->port->meta.provides.port= "port";
	help->port->meta.provides.address = help;
        help->port->meta.provides.meta = &help->dzn_meta;
	help->port->meta.requires.port = "";
	help->port->meta.requires.address = 0;
        help->port->meta.requires.meta = 0;
        self->port = help->port;

        itimer_impl* (*f)(locator* loc) = locator_get (dezyne_locator, "timer.create");
        locator *tmp = locator_clone (dezyne_locator);
        locator_set (tmp, "timer.port", self->port);
        help->pimpl = f (tmp);
}
