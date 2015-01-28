// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Dataparam.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(void*);Dataparam* self;} args_port_a0;
typedef struct {int size;void (*f)(void*, int);Dataparam* self;int i;} args_port_a;
typedef struct {int size;void (*f)(void*, int, int);Dataparam* self;int i;int j;} args_port_aa;
typedef struct {int size;void (*f)(void*, int, int, int, int, int, int);Dataparam* self;int a0;int a1;int a2;int a3;int a4;int a5;} args_port_a6;


typedef struct {int size;void (*f)(void*);Dataparam* self;} args_port_e0;
typedef struct {int size;int (*f)(void*);Dataparam* self;} args_port_e0r;
typedef struct {int size;void (*f)(void*, int);Dataparam* self;int i;} args_port_e;
typedef struct {int size;int (*f)(void*, int);Dataparam* self;int i;} args_port_er;
typedef struct {int size;int (*f)(void*, int, int);Dataparam* self;int i;int j;} args_port_eer;
typedef struct {int size;void (*f)(void*, int*);Dataparam* self;int* i;} args_port_eo;
typedef struct {int size;void (*f)(void*, int*, int*);Dataparam* self;int* i;int* j;} args_port_eoo;
typedef struct {int size;void (*f)(void*, int, int*);Dataparam* self;int i;int* j;} args_port_eio;
typedef struct {int size;void (*f)(void*, int*);Dataparam* self;int* i;} args_port_eio2;
typedef struct {int size;int (*f)(void*, int*);Dataparam* self;int* i;} args_port_eor;
typedef struct {int size;int (*f)(void*, int*, int*);Dataparam* self;int* i;int* j;} args_port_eoor;
typedef struct {int size;int (*f)(void*, int, int*);Dataparam* self;int i;int* j;} args_port_eior;
typedef struct {int size;int (*f)(void*, int*);Dataparam* self;int* i;} args_port_eio2r;


static void helper_port_a0(void* args) {
	args_port_a0 *a = args;
	a->f(a->self->port);
}

static void helper_port_a(void* args) {
	args_port_a *a = args;
	a->f(a->self->port, a->i);
}

static void helper_port_aa(void* args) {
	args_port_aa *a = args;
	a->f(a->self->port, a->i, a->j);
}

static void helper_port_a6(void* args) {
	args_port_a6 *a = args;
	a->f(a->self->port, a->a0, a->a1, a->a2, a->a3, a->a4, a->a5);
}



static void helper_port_e0(void* args) {
	args_port_e0 *a = args;
	a->f(a->self);
}

static void helper_port_e0r(void* args) {
	args_port_e0r *a = args;
	a->f(a->self);
}

static void helper_port_e(void* args) {
	args_port_e *a = args;
	a->f(a->self, a->i);
}

static void helper_port_er(void* args) {
	args_port_er *a = args;
	a->f(a->self, a->i);
}

static void helper_port_eer(void* args) {
	args_port_eer *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_port_eo(void* args) {
	args_port_eo *a = args;
	a->f(a->self, a->i);
}

static void helper_port_eoo(void* args) {
	args_port_eoo *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_port_eio(void* args) {
	args_port_eio *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_port_eio2(void* args) {
	args_port_eio2 *a = args;
	a->f(a->self, a->i);
}

static void helper_port_eor(void* args) {
	args_port_eor *a = args;
	a->f(a->self, a->i);
}

static void helper_port_eoor(void* args) {
	args_port_eoor *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_port_eior(void* args) {
	args_port_eior *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_port_eio2r(void* args) {
	args_port_eio2r *a = args;
	a->f(a->self, a->i);
}



static int fun(Dataparam* self);
static int funx(Dataparam* self, int xi);
static int xfunx(Dataparam* self, int xi, int xj);


static int fun(Dataparam* self) {
	(void)self;
	return IDataparam_Status_Yes;
}

static int funx(Dataparam* self, int xi) {
	(void)self;
	xi = xi;
	return IDataparam_Status_Yes;
}

static int xfunx(Dataparam* self, int xi, int xj) {
	(void)self;
	return (xi + xj) / 3;
}


static void port_e0(void* self_) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_e0");
	{
		args_port_a6 a = {sizeof(args_port_a6), self->port->out.a6, self, 0, 1, 2, 3, 4, 5};
		runtime_defer(self->rt, self, helper_port_a6, &a);
	}
}

static int port_e0r(void* self_) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_e0r");
	{
		args_port_a0 a = {sizeof(args_port_a0), self->port->out.a0, self};
		runtime_defer(self->rt, self, helper_port_a0, &a);
	}
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static void port_e(void* self_, int i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_e");
	{
		int pi = i;
		int s = funx(self, pi);
		s = s;
		self->mi = pi;
		self->mi = xfunx(self, pi, pi + pi);
		{
			args_port_a a = {sizeof(args_port_a), self->port->out.a, self, self->mi};
			runtime_defer(self->rt, self, helper_port_a, &a);
		}
		{
			args_port_aa a = {sizeof(args_port_aa), self->port->out.aa, self, self->mi, pi};
			runtime_defer(self->rt, self, helper_port_aa, &a);
		}
	}
}

static int port_er(void* self_, int i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_er");
	{
		int pi = i;
		int s = IDataparam_Status_No;
		self->mi = pi;
		{
			args_port_a a = {sizeof(args_port_a), self->port->out.a, self, self->mi};
			runtime_defer(self->rt, self, helper_port_a, &a);
		}
		{
			args_port_aa a = {sizeof(args_port_aa), self->port->out.aa, self, self->mi, pi};
			runtime_defer(self->rt, self, helper_port_aa, &a);
		}
		if (true) {
			self->reply_IDataparam_Status = IDataparam_Status_Yes;
		}
		else {
			self->reply_IDataparam_Status = s;
		}
	}
	return self->reply_IDataparam_Status;
}

static int port_eer(void* self_, int i, int j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eer");
	int s = IDataparam_Status_No;
	{
		args_port_a a = {sizeof(args_port_a), self->port->out.a, self, j};
		runtime_defer(self->rt, self, helper_port_a, &a);
	}
	{
		args_port_aa a = {sizeof(args_port_aa), self->port->out.aa, self, j, i};
		runtime_defer(self->rt, self, helper_port_aa, &a);
	}
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static void port_eo(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eo");
	*i = 234;
}

static void port_eoo(void* self_, int* i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eoo");
	*i = 123;
	*j = 456;
}

static void port_eio(void* self_, int i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eio");
	*j = i;
}

static void port_eio2(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eio2");
	int t = *i;
	*i = t + 123;
}

static int port_eor(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eor");
	*i = 234;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static int port_eoor(void* self_, int* i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eoor");
	*i = 123;
	*j = 456;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static int port_eior(void* self_, int i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eior");
	*j = i;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static int port_eio2r(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eio2r");
	int t = *i;
	*i = t + 123;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static void callback_port_e0(void* self_) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_e0 a = {sizeof(args_port_e0), port_e0, self};
	runtime_event(helper_port_e0, &a);
}

static int callback_port_e0r(void* self_) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_e0r a = {sizeof(args_port_e0r), port_e0r, self};
	runtime_event(helper_port_e0r, &a);
	return self->reply_IDataparam_Status;
}

static void callback_port_e(void* self_, int i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_e a = {sizeof(args_port_e), port_e, self, i};
	runtime_event(helper_port_e, &a);
}

static int callback_port_er(void* self_, int i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_er a = {sizeof(args_port_er), port_er, self, i};
	runtime_event(helper_port_er, &a);
	return self->reply_IDataparam_Status;
}

static int callback_port_eer(void* self_, int i, int j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eer a = {sizeof(args_port_eer), port_eer, self, i, j};
	runtime_event(helper_port_eer, &a);
	return self->reply_IDataparam_Status;
}

static void callback_port_eo(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eo a = {sizeof(args_port_eo), port_eo, self, i};
	runtime_event(helper_port_eo, &a);
}

static void callback_port_eoo(void* self_, int* i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eoo a = {sizeof(args_port_eoo), port_eoo, self, i, j};
	runtime_event(helper_port_eoo, &a);
}

static void callback_port_eio(void* self_, int i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eio a = {sizeof(args_port_eio), port_eio, self, i, j};
	runtime_event(helper_port_eio, &a);
}

static void callback_port_eio2(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eio2 a = {sizeof(args_port_eio2), port_eio2, self, i};
	runtime_event(helper_port_eio2, &a);
}

static int callback_port_eor(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eor a = {sizeof(args_port_eor), port_eor, self, i};
	runtime_event(helper_port_eor, &a);
	return self->reply_IDataparam_Status;
}

static int callback_port_eoor(void* self_, int* i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eoor a = {sizeof(args_port_eoor), port_eoor, self, i, j};
	runtime_event(helper_port_eoor, &a);
	return self->reply_IDataparam_Status;
}

static int callback_port_eior(void* self_, int i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eior a = {sizeof(args_port_eior), port_eior, self, i, j};
	runtime_event(helper_port_eior, &a);
	return self->reply_IDataparam_Status;
}

static int callback_port_eio2r(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	args_port_eio2r a = {sizeof(args_port_eio2r), port_eio2r, self, i};
	runtime_event(helper_port_eio2r, &a);
	return self->reply_IDataparam_Status;
}


void Dataparam_init (Dataparam* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->mi = 0;
	self->s = IDataparam_Status_Yes;
	self->port = &self->port_;
	self->port->in.e0 = callback_port_e0;
	self->port->in.e0r = callback_port_e0r;
	self->port->in.e = callback_port_e;
	self->port->in.er = callback_port_er;
	self->port->in.eer = callback_port_eer;
	self->port->in.eo = callback_port_eo;
	self->port->in.eoo = callback_port_eoo;
	self->port->in.eio = callback_port_eio;
	self->port->in.eio2 = callback_port_eio2;
	self->port->in.eor = callback_port_eor;
	self->port->in.eoor = callback_port_eoor;
	self->port->in.eior = callback_port_eior;
	self->port->in.eio2r = callback_port_eio2r;
	self->port->in.self = self;
}
