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

#include "Dataparam.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>

static char const* IDataparam_Status_to_string(IDataparam_Status v)
{
	switch(v)
	{
		case IDataparam_Status_Yes: return "Status_Yes";
		case IDataparam_Status_No: return "Status_No";

	}
	return "";
}




typedef struct {int size;void (*f)(IDataparam*);Dataparam* self;} args_port_a0;
typedef struct {int size;void (*f)(IDataparam*,int);Dataparam* self;int i;} args_port_a;
typedef struct {int size;void (*f)(IDataparam*,int, int);Dataparam* self;int i;int j;} args_port_aa;
typedef struct {int size;void (*f)(IDataparam*,int, int, int, int, int, int);Dataparam* self;int a0;int a1;int a2;int a3;int a4;int a5;} args_port_a6;


typedef struct {int size;void (*f)(Dataparam*);Dataparam* self;} args_port_e0;
typedef struct {int size;int (*f)(Dataparam*);Dataparam* self;} args_port_e0r;
typedef struct {int size;void (*f)(Dataparam*,int);Dataparam* self;int i;} args_port_e;
typedef struct {int size;int (*f)(Dataparam*,int);Dataparam* self;int i;} args_port_er;
typedef struct {int size;int (*f)(Dataparam*,int, int);Dataparam* self;int i;int j;} args_port_eer;
typedef struct {int size;void (*f)(Dataparam*,int*);Dataparam* self;int* i;} args_port_eo;
typedef struct {int size;void (*f)(Dataparam*,int*, int*);Dataparam* self;int* i;int* j;} args_port_eoo;
typedef struct {int size;void (*f)(Dataparam*,int, int*);Dataparam* self;int i;int* j;} args_port_eio;
typedef struct {int size;void (*f)(Dataparam*,int*);Dataparam* self;int* i;} args_port_eio2;
typedef struct {int size;int (*f)(Dataparam*,int*);Dataparam* self;int* i;} args_port_eor;
typedef struct {int size;int (*f)(Dataparam*,int*, int*);Dataparam* self;int* i;int* j;} args_port_eoor;
typedef struct {int size;int (*f)(Dataparam*,int, int*);Dataparam* self;int i;int* j;} args_port_eior;
typedef struct {int size;int (*f)(Dataparam*,int*);Dataparam* self;int* i;} args_port_eio2r;


static void helper_port_a0(void* args) {
	args_port_a0 *a = args;
	a->f(a->self->port);
}

static void helper_port_a(void* args) {
	args_port_a *a = args;
	a->f(a->self->port,a->i);
}

static void helper_port_aa(void* args) {
	args_port_aa *a = args;
	a->f(a->self->port,a->i, a->j);
}

static void helper_port_a6(void* args) {
	args_port_a6 *a = args;
	a->f(a->self->port,a->a0, a->a1, a->a2, a->a3, a->a4, a->a5);
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
	a->f(a->self,a->i);
}

static void helper_port_er(void* args) {
	args_port_er *a = args;
	a->f(a->self,a->i);
}

static void helper_port_eer(void* args) {
	args_port_eer *a = args;
	a->f(a->self,a->i, a->j);
}

static void helper_port_eo(void* args) {
	args_port_eo *a = args;
	a->f(a->self,a->i);
}

static void helper_port_eoo(void* args) {
	args_port_eoo *a = args;
	a->f(a->self,a->i, a->j);
}

static void helper_port_eio(void* args) {
	args_port_eio *a = args;
	a->f(a->self,a->i, a->j);
}

static void helper_port_eio2(void* args) {
	args_port_eio2 *a = args;
	a->f(a->self,a->i);
}

static void helper_port_eor(void* args) {
	args_port_eor *a = args;
	a->f(a->self,a->i);
}

static void helper_port_eoor(void* args) {
	args_port_eoor *a = args;
	a->f(a->self,a->i, a->j);
}

static void helper_port_eior(void* args) {
	args_port_eior *a = args;
	a->f(a->self,a->i, a->j);
}

static void helper_port_eio2r(void* args) {
	args_port_eio2r *a = args;
	a->f(a->self,a->i);
}



static int fun(Dataparam* self);
static int funx(Dataparam* self,int xi);
static int xfunx(Dataparam* self,int xi, int xj);


static int fun(Dataparam* self) {
	(void)self;
	return IDataparam_Status_Yes;
}

static int funx(Dataparam* self,int xi) {
	(void)self;
	xi = xi;
	return IDataparam_Status_Yes;
}

static int xfunx(Dataparam* self,int xi, int xj) {
	(void)self;
	return (xi + xj) / 2;
}


static void port_e0(Dataparam* self) {
	(void)self;
	{
		self->port->out.a6(self->port,0, 1, 2, 3, 4, 5);
	}
}

static int port_e0r(Dataparam* self) {
	(void)self;
	{
		self->port->out.a0(self->port);
		self->reply_IDataparam_Status = IDataparam_Status_Yes;
	}
	return self->reply_IDataparam_Status;
}

static void port_e(Dataparam* self,int i) {
	(void)self;
	{
		int pi = i;
		{
			int s = funx(self, pi);
			s = s;
			self->mi = pi;
			self->mi = xfunx(self, pi, pi);
			self->port->out.a(self->port,self->mi);
			self->port->out.aa(self->port,self->mi, pi);
		}
	}
}

static int port_er(Dataparam* self,int i) {
	(void)self;
	{
		int pi = i;
		{
			int s = IDataparam_Status_No;
			self->mi = pi;
			self->port->out.a(self->port,self->mi);
			self->port->out.aa(self->port,self->mi, pi);
			if (true) {
				self->reply_IDataparam_Status = IDataparam_Status_Yes;
			}
			else {
				self->reply_IDataparam_Status = s;
			}
		}
	}
	return self->reply_IDataparam_Status;
}

static int port_eer(Dataparam* self,int i, int j) {
	(void)self;
	{
		int s = IDataparam_Status_No;
		self->port->out.a(self->port,j);
		self->port->out.aa(self->port,j, i);
		self->reply_IDataparam_Status = s;
	}
	return self->reply_IDataparam_Status;
}

static void port_eo(Dataparam* self,int* i) {
	(void)self;
	{
		*i = 234;
	}
}

static void port_eoo(Dataparam* self,int* i, int* j) {
	(void)self;
	{
		*i = 123;
		*j = 456;
	}
}

static void port_eio(Dataparam* self,int i, int* j) {
	(void)self;
	{
		*j = i;
	}
}

static void port_eio2(Dataparam* self,int* i) {
	(void)self;
	{
		int t = *i;
		*i = 123 + 123;
	}
}

static int port_eor(Dataparam* self,int* i) {
	(void)self;
	{
		*i = 234;
		self->reply_IDataparam_Status = IDataparam_Status_Yes;
	}
	return self->reply_IDataparam_Status;
}

static int port_eoor(Dataparam* self,int* i, int* j) {
	(void)self;
	{
		*i = 123;
		*j = 456;
		self->reply_IDataparam_Status = IDataparam_Status_Yes;
	}
	return self->reply_IDataparam_Status;
}

static int port_eior(Dataparam* self,int i, int* j) {
	(void)self;
	{
		*j = i;
		self->reply_IDataparam_Status = IDataparam_Status_Yes;
	}
	return self->reply_IDataparam_Status;
}

static int port_eio2r(Dataparam* self,int* i) {
	(void)self;
	{
		int t = *i;
		*i = 123 + 123;
		self->reply_IDataparam_Status = IDataparam_Status_Yes;
	}
	return self->reply_IDataparam_Status;
}

static void call_in_port_e0(IDataparam* self) {
	runtime_trace_in(&self->in, &self->out, "e0");
	args_port_e0 a = {sizeof(args_port_e0), port_e0, self->in.self};
	runtime_event(helper_port_e0, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static int call_in_port_e0r(IDataparam* self) {
	runtime_trace_in(&self->in, &self->out, "e0r");
	args_port_e0r a = {sizeof(args_port_e0r), port_e0r, self->in.self};
	runtime_event(helper_port_e0r, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}
static void call_in_port_e(IDataparam* self,int i) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_port_e a = {sizeof(args_port_e), port_e, self->in.self,i};
	runtime_event(helper_port_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static int call_in_port_er(IDataparam* self,int i) {
	runtime_trace_in(&self->in, &self->out, "er");
	args_port_er a = {sizeof(args_port_er), port_er, self->in.self,i};
	runtime_event(helper_port_er, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}
static int call_in_port_eer(IDataparam* self,int i, int j) {
	runtime_trace_in(&self->in, &self->out, "eer");
	args_port_eer a = {sizeof(args_port_eer), port_eer, self->in.self,i, j};
	runtime_event(helper_port_eer, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}
static void call_in_port_eo(IDataparam* self,int* i) {
	runtime_trace_in(&self->in, &self->out, "eo");
	args_port_eo a = {sizeof(args_port_eo), port_eo, self->in.self,i};
	runtime_event(helper_port_eo, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_port_eoo(IDataparam* self,int* i, int* j) {
	runtime_trace_in(&self->in, &self->out, "eoo");
	args_port_eoo a = {sizeof(args_port_eoo), port_eoo, self->in.self,i, j};
	runtime_event(helper_port_eoo, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_port_eio(IDataparam* self,int i, int* j) {
	runtime_trace_in(&self->in, &self->out, "eio");
	args_port_eio a = {sizeof(args_port_eio), port_eio, self->in.self,i, j};
	runtime_event(helper_port_eio, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_port_eio2(IDataparam* self,int* i) {
	runtime_trace_in(&self->in, &self->out, "eio2");
	args_port_eio2 a = {sizeof(args_port_eio2), port_eio2, self->in.self,i};
	runtime_event(helper_port_eio2, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static int call_in_port_eor(IDataparam* self,int* i) {
	runtime_trace_in(&self->in, &self->out, "eor");
	args_port_eor a = {sizeof(args_port_eor), port_eor, self->in.self,i};
	runtime_event(helper_port_eor, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}
static int call_in_port_eoor(IDataparam* self,int* i, int* j) {
	runtime_trace_in(&self->in, &self->out, "eoor");
	args_port_eoor a = {sizeof(args_port_eoor), port_eoor, self->in.self,i, j};
	runtime_event(helper_port_eoor, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}
static int call_in_port_eior(IDataparam* self,int i, int* j) {
	runtime_trace_in(&self->in, &self->out, "eior");
	args_port_eior a = {sizeof(args_port_eior), port_eior, self->in.self,i, j};
	runtime_event(helper_port_eior, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}
static int call_in_port_eio2r(IDataparam* self,int* i) {
	runtime_trace_in(&self->in, &self->out, "eio2r");
	args_port_eio2r a = {sizeof(args_port_eio2r), port_eio2r, self->in.self,i};
	runtime_event(helper_port_eio2r, &a);
	Dataparam* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IDataparam_Status_to_string (self_->reply_IDataparam_Status));
	return self_->reply_IDataparam_Status;
}

void Dataparam_init (Dataparam* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->mi = 0;
	self->s = IDataparam_Status_Yes;
	self->port = &self->port_;
	self->port->in.e0 = call_in_port_e0;
	self->port->in.e0r = call_in_port_e0r;
	self->port->in.e = call_in_port_e;
	self->port->in.er = call_in_port_er;
	self->port->in.eer = call_in_port_eer;
	self->port->in.eo = call_in_port_eo;
	self->port->in.eoo = call_in_port_eoo;
	self->port->in.eio = call_in_port_eio;
	self->port->in.eio2 = call_in_port_eio2;
	self->port->in.eor = call_in_port_eor;
	self->port->in.eoor = call_in_port_eoor;
	self->port->in.eior = call_in_port_eior;
	self->port->in.eio2r = call_in_port_eio2r;
	self->port->in.name = "port";
	self->port->in.self = self;
	self->port->out.name = "";
	self->port->out.self = 0;
}
