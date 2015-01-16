// Dezyne --- Dezyne command line tools
//
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

#include "logger.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>







static void internal_log_log(void* self_) {
	logger* self = self_;
	(void)self;
	DZN_LOG("logger.log_log");
	{
	}
}

static void opaque_log_log(void* a) {
	typedef struct {logger* self;} args;
	args* b = a;
	internal_log_log(b->self);
}

static void log_log(void* self_) {
	logger* self = ((ilogger*)self_)->in.self;
	typedef struct {logger* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_log_log, a);
}


void logger_init (logger* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->log = &self->log_;
	self->log->in.log = log_log;
	self->log->in.self = self;
}
