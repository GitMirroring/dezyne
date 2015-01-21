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

#ifndef DEZYNE_INCOMPLETE_WITH_MODELING_EVENT_H
#define DEZYNE_INCOMPLETE_WITH_MODELING_EVENT_H

#include "iincomplete_with_modeling_event.h"
#include "iincomplete_with_modeling_event.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	runtime* rt;
	iincomplete_with_modeling_event p_;
	iincomplete_with_modeling_event* p;
	iincomplete_with_modeling_event r_;
	iincomplete_with_modeling_event* r;
} incomplete_with_modeling_event;

void incomplete_with_modeling_event_init(incomplete_with_modeling_event* self, locator* dezyne_locator);



#endif // DEZYNE_INCOMPLETE_WITH_MODELING_EVENT_H
