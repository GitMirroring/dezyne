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

#include "Dataparam.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {Dataparam* self;} args_port_a0;
typedef struct {Dataparam* self;int i;} args_port_a;
typedef struct {Dataparam* self;int i; int j;} args_port_aa;
typedef struct {Dataparam* self;int a0; int a1; int a2; int a3; int a4; int a5;} args_port_a6;


static void opaque_port_a0(void* args) {
	args_port_a0 *a = args;
	void (*f)(void*) = a->self->port->out.a0;
	f(a->self->port);
}

static void opaque_port_a(void* args) {
	args_port_a *a = args;
	void (*f)(void*, int i) = a->self->port->out.a;
	f(a->self->port, a->i);
}

static void opaque_port_aa(void* args) {
	args_port_aa *a = args;
	void (*f)(void*, int i, int j) = a->self->port->out.aa;
	f(a->self->port, a->i,a->j);
}

static void opaque_port_a6(void* args) {
	args_port_a6 *a = args;
	void (*f)(void*, int a0, int a1, int a2, int a3, int a4, int a5) = a->self->port->out.a6;
	f(a->self->port, a->a0,a->a1,a->a2,a->a3,a->a4,a->a5);
}



static void internal_port_e0(void* self_) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_e0");
	{
		args_port_a6 a = {self, 0, 1, 2, 3, 4, 5};
		args_port_a6* p = malloc(sizeof(args_port_a6));
		memcpy (p, &a, sizeof(args_port_a6));
		runtime_defer(self->rt, self, opaque_port_a6, p);
	}
}

static int internal_port_e0r(void* self_) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_e0r");
	{
		args_port_a0 a = {self};
		args_port_a0* p = malloc(sizeof(args_port_a0));
		memcpy (p, &a, sizeof(args_port_a0));
		runtime_defer(self->rt, self, opaque_port_a0, p);
	}
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static void internal_port_e(void* self_, int i) {
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
			args_port_a a = {self, self->mi};
			args_port_a* p = malloc(sizeof(args_port_a));
			memcpy (p, &a, sizeof(args_port_a));
			runtime_defer(self->rt, self, opaque_port_a, p);
		}
		{
			args_port_aa a = {self, self->mi, pi};
			args_port_aa* p = malloc(sizeof(args_port_aa));
			memcpy (p, &a, sizeof(args_port_aa));
			runtime_defer(self->rt, self, opaque_port_aa, p);
		}
	}
}

static int internal_port_er(void* self_, int i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_er");
	{
		int pi = i;
		int s = IDataparam_Status_No;
		self->mi = pi;
		{
			args_port_a a = {self, self->mi};
			args_port_a* p = malloc(sizeof(args_port_a));
			memcpy (p, &a, sizeof(args_port_a));
			runtime_defer(self->rt, self, opaque_port_a, p);
		}
		{
			args_port_aa a = {self, self->mi, pi};
			args_port_aa* p = malloc(sizeof(args_port_aa));
			memcpy (p, &a, sizeof(args_port_aa));
			runtime_defer(self->rt, self, opaque_port_aa, p);
		}
		self->reply_IDataparam_Status = s;
	}
	return self->reply_IDataparam_Status;
}

static int internal_port_eer(void* self_, int i, int j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eer");
	int s = IDataparam_Status_No;
	{
		args_port_a a = {self, j};
		args_port_a* p = malloc(sizeof(args_port_a));
		memcpy (p, &a, sizeof(args_port_a));
		runtime_defer(self->rt, self, opaque_port_a, p);
	}
	{
		args_port_aa a = {self, j, i};
		args_port_aa* p = malloc(sizeof(args_port_aa));
		memcpy (p, &a, sizeof(args_port_aa));
		runtime_defer(self->rt, self, opaque_port_aa, p);
	}
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static void internal_port_eo(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eo");
	*i = 234;
}

static void internal_port_eoo(void* self_, int* i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eoo");
	*i = 123;
	*j = 456;
}

static void internal_port_eio(void* self_, int i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eio");
	*j = i;
}

static void internal_port_eio2(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eio2");
	int t = *i;
	*i = t + 123;
}

static int internal_port_eor(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eor");
	*i = 234;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static int internal_port_eoor(void* self_, int* i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eoor");
	*i = 123;
	*j = 456;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static int internal_port_eior(void* self_, int i, int* j) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eior");
	*j = i;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static int internal_port_eio2r(void* self_, int* i) {
	Dataparam* self = self_;
	(void)self;
	DZN_LOG("Dataparam.port_eio2r");
	int t = *i;
	*i = t + 123;
	self->reply_IDataparam_Status = IDataparam_Status_Yes;
	return self->reply_IDataparam_Status;
}

static void opaque_port_e0(void* a) {
	typedef struct {Dataparam* self;} args;
	args* b = a;
	internal_port_e0(b->self);
}

static int opaque_port_e0r(void* a) {
	typedef struct {Dataparam* self;} args;
	args* b = a;
	internal_port_e0r(b->self);
	return b->self->reply_IDataparam_Status;
}

static void opaque_port_e(void* a) {
	typedef struct {Dataparam* self;int i;} args;
	args* b = a;
	internal_port_e(b->self, b->i);
}

static int opaque_port_er(void* a) {
	typedef struct {Dataparam* self;int i;} args;
	args* b = a;
	internal_port_er(b->self, b->i);
	return b->self->reply_IDataparam_Status;
}

static int opaque_port_eer(void* a) {
	typedef struct {Dataparam* self;int i; int j;} args;
	args* b = a;
	internal_port_eer(b->self, b->i,b->j);
	return b->self->reply_IDataparam_Status;
}

static void opaque_port_eo(void* a) {
	typedef struct {Dataparam* self;int* i;} args;
	args* b = a;
	internal_port_eo(b->self, b->i);
}

static void opaque_port_eoo(void* a) {
	typedef struct {Dataparam* self;int* i; int* j;} args;
	args* b = a;
	internal_port_eoo(b->self, b->i,b->j);
}

static void opaque_port_eio(void* a) {
	typedef struct {Dataparam* self;int i; int* j;} args;
	args* b = a;
	internal_port_eio(b->self, b->i,b->j);
}

static void opaque_port_eio2(void* a) {
	typedef struct {Dataparam* self;int* i;} args;
	args* b = a;
	internal_port_eio2(b->self, b->i);
}

static int opaque_port_eor(void* a) {
	typedef struct {Dataparam* self;int* i;} args;
	args* b = a;
	internal_port_eor(b->self, b->i);
	return b->self->reply_IDataparam_Status;
}

static int opaque_port_eoor(void* a) {
	typedef struct {Dataparam* self;int* i; int* j;} args;
	args* b = a;
	internal_port_eoor(b->self, b->i,b->j);
	return b->self->reply_IDataparam_Status;
}

static int opaque_port_eior(void* a) {
	typedef struct {Dataparam* self;int i; int* j;} args;
	args* b = a;
	internal_port_eior(b->self, b->i,b->j);
	return b->self->reply_IDataparam_Status;
}

static int opaque_port_eio2r(void* a) {
	typedef struct {Dataparam* self;int* i;} args;
	args* b = a;
	internal_port_eio2r(b->self, b->i);
	return b->self->reply_IDataparam_Status;
}

static void port_e0(void* self_) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_port_e0, a);
}

static int port_e0r(void* self_) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_port_e0r, a);
	return self->reply_IDataparam_Status;
}

static void port_e(void* self_, int i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_port_e, a);
}

static int port_er(void* self_, int i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_port_er, a);
	return self->reply_IDataparam_Status;
}

static int port_eer(void* self_, int i, int j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int i; int j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_port_eer, a);
	return self->reply_IDataparam_Status;
}

static void port_eo(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_port_eo, a);
}

static void port_eoo(void* self_, int* i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int* i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_port_eoo, a);
}

static void port_eio(void* self_, int i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_port_eio, a);
}

static void port_eio2(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_port_eio2, a);
}

static int port_eor(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_port_eor, a);
	return self->reply_IDataparam_Status;
}

static int port_eoor(void* self_, int* i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int* i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_port_eoor, a);
	return self->reply_IDataparam_Status;
}

static int port_eior(void* self_, int i, int* j) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_port_eior, a);
	return self->reply_IDataparam_Status;
}

static int port_eio2r(void* self_, int* i) {
	Dataparam* self = ((IDataparam*)self_)->in.self;
	typedef struct {Dataparam* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_port_eio2r, a);
	return self->reply_IDataparam_Status;
}

int fun(Dataparam* self) {
	(void)self;
	return IDataparam_Status_Yes;
}

int funx(Dataparam* self, int xi) {
	(void)self;
	xi = xi;
	return IDataparam_Status_Yes;
}

int xfunx(Dataparam* self, int xi, int xj) {
	(void)self;
	return (xi + xj) / 3;
}

void Dataparam_init (Dataparam* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->mi = 0;
	self->s = IDataparam_Status_Yes;
	self->port = &self->port_;
	self->port->in.e0 = port_e0;
	self->port->in.e0r = port_e0r;
	self->port->in.e = port_e;
	self->port->in.er = port_er;
	self->port->in.eer = port_eer;
	self->port->in.eo = port_eo;
	self->port->in.eoo = port_eoo;
	self->port->in.eio = port_eio;
	self->port->in.eio2 = port_eio2;
	self->port->in.eor = port_eor;
	self->port->in.eoor = port_eoor;
	self->port->in.eior = port_eior;
	self->port->in.eio2r = port_eio2r;
	self->port->in.self = self;
}
