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

#include "Comp.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
	Comp_State_Uninitialized, Comp_State_Initialized, Comp_State_Error
} Comp_State;






static int internal_client_initialize(void* self_) {
	Comp* self = self_;
	(void)self;
	DZN_LOG("Comp.client_initialize");
	if (self->s == Comp_State_Uninitialized) {
		int res = self->device_A->in.initialize(self->device_A);
		if (res == IDevice_result_t_OK)
		{
			res = self->device_A->in.calibrate(self->device_A);
		}
		if (res == IDevice_result_t_OK)
		{
			self->s = Comp_State_Initialized;
			self->reply_IDevice_result_t = IDevice_result_t_OK;
		}
		else
		{
			self->s = Comp_State_Uninitialized;
			self->reply_IDevice_result_t = IDevice_result_t_NOK;
		}
	}
	else if (self->s == Comp_State_Initialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Error) {
		assert(false);
	}
	return self->reply_IComp_result_t;
}

static int internal_client_recover(void* self_) {
	Comp* self = self_;
	(void)self;
	DZN_LOG("Comp.client_recover");
	if (self->s == Comp_State_Uninitialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Initialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Error) {
		int res = self->device_A->in.calibrate(self->device_A);
		if (res == IDevice_result_t_OK)
		{
			self->s = Comp_State_Initialized;
			self->reply_IDevice_result_t = IDevice_result_t_OK;
		}
		else
		{
			self->s = Comp_State_Error;
			self->reply_IDevice_result_t = IDevice_result_t_NOK;
		}
	}
	return self->reply_IComp_result_t;
}

static int internal_client_perform_actions(void* self_) {
	Comp* self = self_;
	(void)self;
	DZN_LOG("Comp.client_perform_actions");
	if (self->s == Comp_State_Uninitialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Initialized) {
		int res = self->device_A->in.perform_action1(self->device_A);
		if (res == IDevice_result_t_OK)
		{
			res = self->device_A->in.perform_action2(self->device_A);
		}
		if (res == IDevice_result_t_OK)
		{
			self->s = Comp_State_Initialized;
			self->reply_IDevice_result_t = IDevice_result_t_OK;
		}
		else
		{
			self->s = Comp_State_Error;
			self->reply_IDevice_result_t = IDevice_result_t_NOK;
		}
	}
	else if (self->s == Comp_State_Error) {
		assert(false);
	}
	return self->reply_IComp_result_t;
}

static int opaque_client_initialize(void* a) {
	typedef struct {Comp* self;} args;
	args* b = a;
	internal_client_initialize(b->self);
	return b->self->reply_IComp_result_t;
}

static int opaque_client_recover(void* a) {
	typedef struct {Comp* self;} args;
	args* b = a;
	internal_client_recover(b->self);
	return b->self->reply_IComp_result_t;
}

static int opaque_client_perform_actions(void* a) {
	typedef struct {Comp* self;} args;
	args* b = a;
	internal_client_perform_actions(b->self);
	return b->self->reply_IComp_result_t;
}

static int client_initialize(void* self_) {
	Comp* self = ((IComp*)self_)->in.self;
	typedef struct {Comp* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_client_initialize, a);
	return self->reply_IComp_result_t;
}

static int client_recover(void* self_) {
	Comp* self = ((IComp*)self_)->in.self;
	typedef struct {Comp* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_client_recover, a);
	return self->reply_IComp_result_t;
}

static int client_perform_actions(void* self_) {
	Comp* self = ((IComp*)self_)->in.self;
	typedef struct {Comp* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_client_perform_actions, a);
	return self->reply_IComp_result_t;
}


void Comp_init (Comp* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->s = Comp_State_Uninitialized;
	self->client = &self->client_;
	self->client->in.initialize = client_initialize;
	self->client->in.recover = client_recover;
	self->client->in.perform_actions = client_perform_actions;
	self->client->in.self = self;
	self->device_A = &self->device_A_;
	self->device_A->out.self = self;
}
