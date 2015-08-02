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
#include <string.h>

static char const* IComp_result_t_to_string(IComp_result_t v)
{
	switch(v)
	{
		case IComp_result_t_OK: return "result_t_OK";
		case IComp_result_t_NOK: return "result_t_NOK";

	}
	return "";
}
static char const* IDevice_result_t_to_string(IDevice_result_t v)
{
	switch(v)
	{
		case IDevice_result_t_OK: return "result_t_OK";
		case IDevice_result_t_NOK: return "result_t_NOK";

	}
	return "";
}


typedef enum {
	Comp_State_Uninitialized, Comp_State_Initialized, Comp_State_Error
} Comp_State;




typedef struct {int size;int (*f)(Comp*);Comp* self;} args_client_initialize;
typedef struct {int size;int (*f)(Comp*);Comp* self;} args_client_recover;
typedef struct {int size;int (*f)(Comp*);Comp* self;} args_client_perform_actions;




static void helper_client_initialize(void* args) {
	args_client_initialize *a = args;
	a->f(a->self);
}

static void helper_client_recover(void* args) {
	args_client_recover *a = args;
	a->f(a->self);
}

static void helper_client_perform_actions(void* args) {
	args_client_perform_actions *a = args;
	a->f(a->self);
}







static int client_initialize(Comp* self) {
	(void)self;
	if (self->s == Comp_State_Uninitialized) {
		{
			int res = self->device_A->in.initialize(self->device_A);
			if (res == IDevice_result_t_OK) {
				res = self->device_A->in.calibrate(self->device_A);
			}
			if (res == IDevice_result_t_OK) {
				self->s = Comp_State_Initialized;
				self->reply_IDevice_result_t = IDevice_result_t_OK;
			}
			else {
				self->s = Comp_State_Uninitialized;
				self->reply_IDevice_result_t = IDevice_result_t_NOK;
			}
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

static int client_recover(Comp* self) {
	(void)self;
	if (self->s == Comp_State_Uninitialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Initialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Error) {
		{
			int res = self->device_A->in.calibrate(self->device_A);
			if (res == IDevice_result_t_OK) {
				self->s = Comp_State_Initialized;
				self->reply_IDevice_result_t = IDevice_result_t_OK;
			}
			else {
				self->s = Comp_State_Error;
				self->reply_IDevice_result_t = IDevice_result_t_NOK;
			}
		}
	}
	return self->reply_IComp_result_t;
}

static int client_perform_actions(Comp* self) {
	(void)self;
	if (self->s == Comp_State_Uninitialized) {
		assert(false);
	}
	else if (self->s == Comp_State_Initialized) {
		{
			int res = self->device_A->in.perform_action1(self->device_A);
			if (res == IDevice_result_t_OK) {
				res = self->device_A->in.perform_action2(self->device_A);
			}
			if (res == IDevice_result_t_OK) {
				self->s = Comp_State_Initialized;
				self->reply_IDevice_result_t = IDevice_result_t_OK;
			}
			else {
				self->s = Comp_State_Error;
				self->reply_IDevice_result_t = IDevice_result_t_NOK;
			}
		}
	}
	else if (self->s == Comp_State_Error) {
		assert(false);
	}
	return self->reply_IComp_result_t;
}

static int call_in_client_initialize(IComp* self) {
	runtime_trace_in(&self->in, &self->out, "initialize");
	args_client_initialize a = {sizeof(args_client_initialize), client_initialize, self->in.self};
	runtime_event(helper_client_initialize, &a);
	Comp* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IComp_result_t_to_string (self_->reply_IComp_result_t));
	return self_->reply_IComp_result_t;
}
static int call_in_client_recover(IComp* self) {
	runtime_trace_in(&self->in, &self->out, "recover");
	args_client_recover a = {sizeof(args_client_recover), client_recover, self->in.self};
	runtime_event(helper_client_recover, &a);
	Comp* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IComp_result_t_to_string (self_->reply_IComp_result_t));
	return self_->reply_IComp_result_t;
}
static int call_in_client_perform_actions(IComp* self) {
	runtime_trace_in(&self->in, &self->out, "perform_actions");
	args_client_perform_actions a = {sizeof(args_client_perform_actions), client_perform_actions, self->in.self};
	runtime_event(helper_client_perform_actions, &a);
	Comp* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IComp_result_t_to_string (self_->reply_IComp_result_t));
	return self_->reply_IComp_result_t;
}

void Comp_init (Comp* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->s = Comp_State_Uninitialized;
	self->client = &self->client_;
	self->client->in.initialize = call_in_client_initialize;
	self->client->in.recover = call_in_client_recover;
	self->client->in.perform_actions = call_in_client_perform_actions;
	self->client->in.name = "client";
	self->client->in.self = self;
	self->client->out.name = "";
	self->client->out.self = 0;
	self->device_A = &self->device_A_;
	self->device_A->in.name = "";
	self->device_A->in.self = 0;
	self->device_A->out.name = "device_A";
	self->device_A->out.self = self;
}
