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

#include "proxy.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(IDataparam*);proxy* self;} args_top_a0;
typedef struct {int size;void (*f)(IDataparam*, int);proxy* self;int i;} args_top_a;
typedef struct {int size;void (*f)(IDataparam*, int, int);proxy* self;int i;int j;} args_top_aa;
typedef struct {int size;void (*f)(IDataparam*, int, int, int, int, int, int);proxy* self;int a0;int a1;int a2;int a3;int a4;int a5;} args_top_a6;


typedef struct {int size;void (*f)(proxy*);proxy* self;} args_top_e0;
typedef struct {int size;int (*f)(proxy*);proxy* self;} args_top_e0r;
typedef struct {int size;void (*f)(proxy*, int);proxy* self;int i;} args_top_e;
typedef struct {int size;int (*f)(proxy*, int);proxy* self;int i;} args_top_er;
typedef struct {int size;int (*f)(proxy*, int, int);proxy* self;int i;int j;} args_top_eer;
typedef struct {int size;void (*f)(proxy*, int*);proxy* self;int* i;} args_top_eo;
typedef struct {int size;void (*f)(proxy*, int*, int*);proxy* self;int* i;int* j;} args_top_eoo;
typedef struct {int size;void (*f)(proxy*, int, int*);proxy* self;int i;int* j;} args_top_eio;
typedef struct {int size;void (*f)(proxy*, int*);proxy* self;int* i;} args_top_eio2;
typedef struct {int size;int (*f)(proxy*, int*);proxy* self;int* i;} args_top_eor;
typedef struct {int size;int (*f)(proxy*, int*, int*);proxy* self;int* i;int* j;} args_top_eoor;
typedef struct {int size;int (*f)(proxy*, int, int*);proxy* self;int i;int* j;} args_top_eior;
typedef struct {int size;int (*f)(proxy*, int*);proxy* self;int* i;} args_top_eio2r;
typedef struct {int size;void (*f)(proxy*);proxy* self;} args_bottom_a0;
typedef struct {int size;void (*f)(proxy*, int);proxy* self;int i;} args_bottom_a;
typedef struct {int size;void (*f)(proxy*, int, int);proxy* self;int i;int j;} args_bottom_aa;
typedef struct {int size;void (*f)(proxy*, int, int, int, int, int, int);proxy* self;int a0;int a1;int a2;int a3;int a4;int a5;} args_bottom_a6;


static void helper_top_a0(void* args) {
	args_top_a0 *a = args;
	a->f(a->self->top);
}

static void helper_top_a(void* args) {
	args_top_a *a = args;
	a->f(a->self->top, a->i);
}

static void helper_top_aa(void* args) {
	args_top_aa *a = args;
	a->f(a->self->top, a->i, a->j);
}

static void helper_top_a6(void* args) {
	args_top_a6 *a = args;
	a->f(a->self->top, a->a0, a->a1, a->a2, a->a3, a->a4, a->a5);
}



static void helper_top_e0(void* args) {
	args_top_e0 *a = args;
	a->f(a->self);
}

static void helper_top_e0r(void* args) {
	args_top_e0r *a = args;
	a->f(a->self);
}

static void helper_top_e(void* args) {
	args_top_e *a = args;
	a->f(a->self, a->i);
}

static void helper_top_er(void* args) {
	args_top_er *a = args;
	a->f(a->self, a->i);
}

static void helper_top_eer(void* args) {
	args_top_eer *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_top_eo(void* args) {
	args_top_eo *a = args;
	a->f(a->self, a->i);
}

static void helper_top_eoo(void* args) {
	args_top_eoo *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_top_eio(void* args) {
	args_top_eio *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_top_eio2(void* args) {
	args_top_eio2 *a = args;
	a->f(a->self, a->i);
}

static void helper_top_eor(void* args) {
	args_top_eor *a = args;
	a->f(a->self, a->i);
}

static void helper_top_eoor(void* args) {
	args_top_eoor *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_top_eior(void* args) {
	args_top_eior *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_top_eio2r(void* args) {
	args_top_eio2r *a = args;
	a->f(a->self, a->i);
}

static void helper_bottom_a0(void* args) {
	args_bottom_a0 *a = args;
	a->f(a->self);
}

static void helper_bottom_a(void* args) {
	args_bottom_a *a = args;
	a->f(a->self, a->i);
}

static void helper_bottom_aa(void* args) {
	args_bottom_aa *a = args;
	a->f(a->self, a->i, a->j);
}

static void helper_bottom_a6(void* args) {
	args_bottom_a6 *a = args;
	a->f(a->self, a->a0, a->a1, a->a2, a->a3, a->a4, a->a5);
}



static void outfunc(proxy* self, int i);
static void deferfunc(proxy* self, int i);


static void outfunc(proxy* self, int i) {
	(void)self;
	int j = i;
	self->bottom->in.eo(self->bottom, &j);
}

static void deferfunc(proxy* self, int i) {
	(void)self;
	{
		args_top_a a = {sizeof(args_top_a), self->top->out.a, self, i};
		runtime_defer(self->rt, self, helper_top_a, &a);
	}
}


static void top_e0(proxy* self) {
	(void)self;
	DZN_LOG("proxy.top_e0");
	self->bottom->in.e0(self->bottom);
}

static int top_e0r(proxy* self) {
	(void)self;
	DZN_LOG("proxy.top_e0r");
	int r = self->bottom->in.e0r(self->bottom);
	self->reply_IDataparam_Status = r;
	return self->reply_IDataparam_Status;
}

static void top_e(proxy* self, int i) {
	(void)self;
	DZN_LOG("proxy.top_e");
	{
		int pi = i;
		self->bottom->in.e(self->bottom, pi);
	}
}

static int top_er(proxy* self, int i) {
	(void)self;
	DZN_LOG("proxy.top_er");
	{
		int pi = i;
		int r = self->bottom->in.er(self->bottom, pi);
		self->reply_IDataparam_Status = r;
	}
	return self->reply_IDataparam_Status;
}

static int top_eer(proxy* self, int i, int j) {
	(void)self;
	DZN_LOG("proxy.top_eer");
	int r = self->bottom->in.eer(self->bottom, i, j);
	self->reply_IDataparam_Status = r;
	return self->reply_IDataparam_Status;
}

static void top_eo(proxy* self, int* i) {
	(void)self;
	DZN_LOG("proxy.top_eo");
	outfunc(self,*i);
}

static void top_eoo(proxy* self, int* i, int* j) {
	(void)self;
	DZN_LOG("proxy.top_eoo");
	self->bottom->in.eoo(self->bottom, &*i, &*j);
}

static void top_eio(proxy* self, int i, int* j) {
	(void)self;
	DZN_LOG("proxy.top_eio");
	self->bottom->in.eio(self->bottom, i, &*j);
}

static void top_eio2(proxy* self, int* i) {
	(void)self;
	DZN_LOG("proxy.top_eio2");
	self->bottom->in.eio2(self->bottom, &*i);
}

static int top_eor(proxy* self, int* i) {
	(void)self;
	DZN_LOG("proxy.top_eor");
	int s = self->bottom->in.eor(self->bottom, i);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static int top_eoor(proxy* self, int* i, int* j) {
	(void)self;
	DZN_LOG("proxy.top_eoor");
	int s = self->bottom->in.eoor(self->bottom, i, j);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static int top_eior(proxy* self, int i, int* j) {
	(void)self;
	DZN_LOG("proxy.top_eior");
	int s = self->bottom->in.eior(self->bottom, i, j);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static int top_eio2r(proxy* self, int* i) {
	(void)self;
	DZN_LOG("proxy.top_eio2r");
	int s = self->bottom->in.eio2r(self->bottom, i);
	self->reply_IDataparam_Status = s;
	return self->reply_IDataparam_Status;
}

static void bottom_a0(proxy* self) {
	(void)self;
	DZN_LOG("proxy.bottom_a0");
	{
		args_top_a0 a = {sizeof(args_top_a0), self->top->out.a0, self};
		runtime_defer(self->rt, self, helper_top_a0, &a);
	}
}

static void bottom_a(proxy* self, int i) {
	(void)self;
	DZN_LOG("proxy.bottom_a");
	deferfunc(self,i);
}

static void bottom_aa(proxy* self, int i, int j) {
	(void)self;
	DZN_LOG("proxy.bottom_aa");
	{
		args_top_aa a = {sizeof(args_top_aa), self->top->out.aa, self, i, j};
		runtime_defer(self->rt, self, helper_top_aa, &a);
	}
}

static void bottom_a6(proxy* self, int a0, int a1, int a2, int a3, int a4, int a5) {
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
			args_top_a6 a = {sizeof(args_top_a6), self->top->out.a6, self, A0, A1, A2, A3, A4, A5};
			runtime_defer(self->rt, self, helper_top_a6, &a);
		}
	}
}

static void callback_top_e0(IDataparam* self) {
	args_top_e0 a = {sizeof(args_top_e0), top_e0, self->in.self};
	runtime_event(helper_top_e0, &a);
}

static int callback_top_e0r(IDataparam* self) {
	args_top_e0r a = {sizeof(args_top_e0r), top_e0r, self->in.self};
	runtime_event(helper_top_e0r, &a);
	return self->reply_IDataparam_Status;
}

static void callback_top_e(IDataparam* self, int i) {
	args_top_e a = {sizeof(args_top_e), top_e, self->in.self, i};
	runtime_event(helper_top_e, &a);
}

static int callback_top_er(IDataparam* self, int i) {
	args_top_er a = {sizeof(args_top_er), top_er, self->in.self, i};
	runtime_event(helper_top_er, &a);
	return self->reply_IDataparam_Status;
}

static int callback_top_eer(IDataparam* self, int i, int j) {
	args_top_eer a = {sizeof(args_top_eer), top_eer, self->in.self, i, j};
	runtime_event(helper_top_eer, &a);
	return self->reply_IDataparam_Status;
}

static void callback_top_eo(IDataparam* self, int* i) {
	args_top_eo a = {sizeof(args_top_eo), top_eo, self->in.self, i};
	runtime_event(helper_top_eo, &a);
}

static void callback_top_eoo(IDataparam* self, int* i, int* j) {
	args_top_eoo a = {sizeof(args_top_eoo), top_eoo, self->in.self, i, j};
	runtime_event(helper_top_eoo, &a);
}

static void callback_top_eio(IDataparam* self, int i, int* j) {
	args_top_eio a = {sizeof(args_top_eio), top_eio, self->in.self, i, j};
	runtime_event(helper_top_eio, &a);
}

static void callback_top_eio2(IDataparam* self, int* i) {
	args_top_eio2 a = {sizeof(args_top_eio2), top_eio2, self->in.self, i};
	runtime_event(helper_top_eio2, &a);
}

static int callback_top_eor(IDataparam* self, int* i) {
	args_top_eor a = {sizeof(args_top_eor), top_eor, self->in.self, i};
	runtime_event(helper_top_eor, &a);
	return self->reply_IDataparam_Status;
}

static int callback_top_eoor(IDataparam* self, int* i, int* j) {
	args_top_eoor a = {sizeof(args_top_eoor), top_eoor, self->in.self, i, j};
	runtime_event(helper_top_eoor, &a);
	return self->reply_IDataparam_Status;
}

static int callback_top_eior(IDataparam* self, int i, int* j) {
	args_top_eior a = {sizeof(args_top_eior), top_eior, self->in.self, i, j};
	runtime_event(helper_top_eior, &a);
	return self->reply_IDataparam_Status;
}

static int callback_top_eio2r(IDataparam* self, int* i) {
	args_top_eio2r a = {sizeof(args_top_eio2r), top_eio2r, self->in.self, i};
	runtime_event(helper_top_eio2r, &a);
	return self->reply_IDataparam_Status;
}

static void callback_bottom_a0(IDataparam* self) {
	args_bottom_a0 a = {sizeof(args_bottom_a0), bottom_a0, self->out.self};
	runtime_event(helper_bottom_a0, &a);
}

static void callback_bottom_a(IDataparam* self, int i) {
	args_bottom_a a = {sizeof(args_bottom_a), bottom_a, self->out.self, i};
	runtime_event(helper_bottom_a, &a);
}

static void callback_bottom_aa(IDataparam* self, int i, int j) {
	args_bottom_aa a = {sizeof(args_bottom_aa), bottom_aa, self->out.self, i, j};
	runtime_event(helper_bottom_aa, &a);
}

static void callback_bottom_a6(IDataparam* self, int a0, int a1, int a2, int a3, int a4, int a5) {
	args_bottom_a6 a = {sizeof(args_bottom_a6), bottom_a6, self->out.self, a0, a1, a2, a3, a4, a5};
	runtime_event(helper_bottom_a6, &a);
}


void proxy_init (proxy* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->top = &self->top_;
	self->top->in.e0 = callback_top_e0;
	self->top->in.e0r = callback_top_e0r;
	self->top->in.e = callback_top_e;
	self->top->in.er = callback_top_er;
	self->top->in.eer = callback_top_eer;
	self->top->in.eo = callback_top_eo;
	self->top->in.eoo = callback_top_eoo;
	self->top->in.eio = callback_top_eio;
	self->top->in.eio2 = callback_top_eio2;
	self->top->in.eor = callback_top_eor;
	self->top->in.eoor = callback_top_eoor;
	self->top->in.eior = callback_top_eior;
	self->top->in.eio2r = callback_top_eio2r;
	self->top->in.self = self;
	self->bottom = &self->bottom_;
	self->bottom->out.self = self;
	self->bottom->out.a0 = callback_bottom_a0;
	self->bottom->out.a = callback_bottom_a;
	self->bottom->out.aa = callback_bottom_aa;
	self->bottom->out.a6 = callback_bottom_a6;
}
