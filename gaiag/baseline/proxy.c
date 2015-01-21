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

#include "proxy.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {proxy* self;} args_top_a0;
typedef struct {proxy* self;int i;} args_top_a;
typedef struct {proxy* self;int i; int j;} args_top_aa;
typedef struct {proxy* self;int a0; int a1; int a2; int a3; int a4; int a5;} args_top_a6;


static void opaque_top_a0(void* args) {
	args_top_a0 *a = args;
	void (*f)(void*) = a->self->top->out.a0;
	f(a->self->top);
}

static void opaque_top_a(void* args) {
	args_top_a *a = args;
	void (*f)(void*, int i) = a->self->top->out.a;
	f(a->self->top, a->i);
}

static void opaque_top_aa(void* args) {
	args_top_aa *a = args;
	void (*f)(void*, int i, int j) = a->self->top->out.aa;
	f(a->self->top, a->i,a->j);
}

static void opaque_top_a6(void* args) {
	args_top_a6 *a = args;
	void (*f)(void*, int a0, int a1, int a2, int a3, int a4, int a5) = a->self->top->out.a6;
	f(a->self->top, a->a0,a->a1,a->a2,a->a3,a->a4,a->a5);
}



static void internal_top_e0(void* self_) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_e0");
	self->bottom->in.e0(self->bottom);
}

static int internal_top_e0r(void* self_) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_e0r");
	int r = self->bottom->in.e0r(self->bottom);
	self->reply_IDataparam_Status = r;
	return self->reply_IDataparam_Status;
}

static void internal_top_e(void* self_, int i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_e");
	{
		int pi = i;
		self->bottom->in.e(self->bottom, pi);
	}
}

static int internal_top_er(void* self_, int i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_er");
	{
		int pi = i;
		int r = self->bottom->in.er(self->bottom, pi);
		self->reply_IDataparam_Status = r;
	}
	return self->reply_IDataparam_Status;
}

static int internal_top_eer(void* self_, int i, int j) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eer");
	int r = self->bottom->in.eer(self->bottom, i, j);
	self->reply_IDataparam_Status = r;
	return self->reply_IDataparam_Status;
}

static void internal_top_eo(void* self_, int* i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eo");
	self->bottom->in.eo(self->bottom, i);
}

static void internal_top_eoo(void* self_, int* i, int* j) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eoo");
	self->bottom->in.eoo(self->bottom, i, j);
}

static void internal_top_eio(void* self_, int i, int* j) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eio");
	self->bottom->in.eio(self->bottom, i, j);
}

static void internal_top_eio2(void* self_, int* i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eio2");
	self->bottom->in.eio2(self->bottom, i);
}

static int internal_top_eor(void* self_, int* i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eor");
	int s = self->bottom->in.eor(self->bottom, i);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static int internal_top_eoor(void* self_, int* i, int* j) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eoor");
	int s = self->bottom->in.eoor(self->bottom, i, j);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static int internal_top_eior(void* self_, int i, int* j) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eior");
	int s = self->bottom->in.eior(self->bottom, i, j);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static int internal_top_eio2r(void* self_, int* i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.top_eio2r");
	int s = self->bottom->in.eio2r(self->bottom, i);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static void internal_bottom_a0(void* self_) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.bottom_a0");
	{
		args_top_a0 a = {self};
		args_top_a0* p = malloc(sizeof(args_top_a0));
		memcpy (p, &a, sizeof(args_top_a0));
		runtime_defer(self->rt, self, opaque_top_a0, p);
	}
}

static void internal_bottom_a(void* self_, int i) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.bottom_a");
	{
		args_top_a a = {self, i};
		args_top_a* p = malloc(sizeof(args_top_a));
		memcpy (p, &a, sizeof(args_top_a));
		runtime_defer(self->rt, self, opaque_top_a, p);
	}
}

static void internal_bottom_aa(void* self_, int i, int j) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.bottom_aa");
	{
		args_top_aa a = {self, i, j};
		args_top_aa* p = malloc(sizeof(args_top_aa));
		memcpy (p, &a, sizeof(args_top_aa));
		runtime_defer(self->rt, self, opaque_top_aa, p);
	}
}

static void internal_bottom_a6(void* self_, int a0, int a1, int a2, int a3, int a4, int a5) {
	proxy* self = self_;
	(void)self;
	DZN_LOG("proxy.bottom_a6");
	{
		int A0 = a0;
		int A1 = a1;
		int A2 = a2;
		int A3 = a3;
		int A4 = a4;
		int A5 = a5;
		{
			args_top_a6 a = {self, A0, A1, A2, A3, A4, A5};
			args_top_a6* p = malloc(sizeof(args_top_a6));
			memcpy (p, &a, sizeof(args_top_a6));
			runtime_defer(self->rt, self, opaque_top_a6, p);
		}
	}
}

static void opaque_top_e0(void* a) {
	typedef struct {proxy* self;} args;
	args* b = a;
	internal_top_e0(b->self);
}

static int opaque_top_e0r(void* a) {
	typedef struct {proxy* self;} args;
	args* b = a;
	internal_top_e0r(b->self);
	return b->self->reply_IDataparam_Status;
}

static void opaque_top_e(void* a) {
	typedef struct {proxy* self;int i;} args;
	args* b = a;
	internal_top_e(b->self, b->i);
}

static int opaque_top_er(void* a) {
	typedef struct {proxy* self;int i;} args;
	args* b = a;
	internal_top_er(b->self, b->i);
	return b->self->reply_IDataparam_Status;
}

static int opaque_top_eer(void* a) {
	typedef struct {proxy* self;int i; int j;} args;
	args* b = a;
	internal_top_eer(b->self, b->i,b->j);
	return b->self->reply_IDataparam_Status;
}

static void opaque_top_eo(void* a) {
	typedef struct {proxy* self;int* i;} args;
	args* b = a;
	internal_top_eo(b->self, b->i);
}

static void opaque_top_eoo(void* a) {
	typedef struct {proxy* self;int* i; int* j;} args;
	args* b = a;
	internal_top_eoo(b->self, b->i,b->j);
}

static void opaque_top_eio(void* a) {
	typedef struct {proxy* self;int i; int* j;} args;
	args* b = a;
	internal_top_eio(b->self, b->i,b->j);
}

static void opaque_top_eio2(void* a) {
	typedef struct {proxy* self;int* i;} args;
	args* b = a;
	internal_top_eio2(b->self, b->i);
}

static int opaque_top_eor(void* a) {
	typedef struct {proxy* self;int* i;} args;
	args* b = a;
	internal_top_eor(b->self, b->i);
	return b->self->reply_IDataparam_Status;
}

static int opaque_top_eoor(void* a) {
	typedef struct {proxy* self;int* i; int* j;} args;
	args* b = a;
	internal_top_eoor(b->self, b->i,b->j);
	return b->self->reply_IDataparam_Status;
}

static int opaque_top_eior(void* a) {
	typedef struct {proxy* self;int i; int* j;} args;
	args* b = a;
	internal_top_eior(b->self, b->i,b->j);
	return b->self->reply_IDataparam_Status;
}

static int opaque_top_eio2r(void* a) {
	typedef struct {proxy* self;int* i;} args;
	args* b = a;
	internal_top_eio2r(b->self, b->i);
	return b->self->reply_IDataparam_Status;
}

static void opaque_bottom_a0(void* a) {
	typedef struct {proxy* self;} args;
	args* b = a;
	internal_bottom_a0(b->self);
}

static void opaque_bottom_a(void* a) {
	typedef struct {proxy* self;int i;} args;
	args* b = a;
	internal_bottom_a(b->self, b->i);
}

static void opaque_bottom_aa(void* a) {
	typedef struct {proxy* self;int i; int j;} args;
	args* b = a;
	internal_bottom_aa(b->self, b->i,b->j);
}

static void opaque_bottom_a6(void* a) {
	typedef struct {proxy* self;int a0; int a1; int a2; int a3; int a4; int a5;} args;
	args* b = a;
	internal_bottom_a6(b->self, b->a0,b->a1,b->a2,b->a3,b->a4,b->a5);
}

static void top_e0(void* self_) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_top_e0, a);
}

static int top_e0r(void* self_) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_top_e0r, a);
	return self->reply_IDataparam_Status;
}

static void top_e(void* self_, int i) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_top_e, a);
}

static int top_er(void* self_, int i) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_top_er, a);
	return self->reply_IDataparam_Status;
}

static int top_eer(void* self_, int i, int j) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int i; int j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_top_eer, a);
	return self->reply_IDataparam_Status;
}

static void top_eo(void* self_, int* i) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_top_eo, a);
}

static void top_eoo(void* self_, int* i, int* j) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int* i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_top_eoo, a);
}

static void top_eio(void* self_, int i, int* j) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_top_eio, a);
}

static void top_eio2(void* self_, int* i) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_top_eio2, a);
}

static int top_eor(void* self_, int* i) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_top_eor, a);
	return self->reply_IDataparam_Status;
}

static int top_eoor(void* self_, int* i, int* j) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int* i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_top_eoor, a);
	return self->reply_IDataparam_Status;
}

static int top_eior(void* self_, int i, int* j) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int i; int* j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_top_eior, a);
	return self->reply_IDataparam_Status;
}

static int top_eio2r(void* self_, int* i) {
	proxy* self = ((IDataparam*)self_)->in.self;
	typedef struct {proxy* self;int* i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_top_eio2r, a);
	return self->reply_IDataparam_Status;
}

static void bottom_a0(void* self_) {
	proxy* self = ((IDataparam*)self_)->out.self;
	typedef struct {proxy* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_bottom_a0, a);
}

static void bottom_a(void* self_, int i) {
	proxy* self = ((IDataparam*)self_)->out.self;
	typedef struct {proxy* self;int i;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	runtime_event(opaque_bottom_a, a);
}

static void bottom_aa(void* self_, int i, int j) {
	proxy* self = ((IDataparam*)self_)->out.self;
	typedef struct {proxy* self;int i; int j;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->i=i;
	a->j=j;
	runtime_event(opaque_bottom_aa, a);
}

static void bottom_a6(void* self_, int a0, int a1, int a2, int a3, int a4, int a5) {
	proxy* self = ((IDataparam*)self_)->out.self;
	typedef struct {proxy* self;int a0; int a1; int a2; int a3; int a4; int a5;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	a->a0=a0;
	a->a1=a1;
	a->a2=a2;
	a->a3=a3;
	a->a4=a4;
	a->a5=a5;
	runtime_event(opaque_bottom_a6, a);
}


void proxy_init (proxy* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->top = &self->top_;
	self->top->in.e0 = top_e0;
	self->top->in.e0r = top_e0r;
	self->top->in.e = top_e;
	self->top->in.er = top_er;
	self->top->in.eer = top_eer;
	self->top->in.eo = top_eo;
	self->top->in.eoo = top_eoo;
	self->top->in.eio = top_eio;
	self->top->in.eio2 = top_eio2;
	self->top->in.eor = top_eor;
	self->top->in.eoor = top_eoor;
	self->top->in.eior = top_eior;
	self->top->in.eio2r = top_eio2r;
	self->top->in.self = self;
	self->bottom = &self->bottom_;
	self->bottom->out.self = self;
	self->bottom->out.a0 = bottom_a0;
	self->bottom->out.a = bottom_a;
	self->bottom->out.aa = bottom_aa;
	self->bottom->out.a6 = bottom_a6;
}
