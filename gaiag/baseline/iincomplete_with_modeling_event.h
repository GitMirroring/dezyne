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

#ifndef DEZYNE_IINCOMPLETE_WITH_MODELING_EVENT_H
#define DEZYNE_IINCOMPLETE_WITH_MODELING_EVENT_H



typedef struct iincomplete_with_modeling_event iincomplete_with_modeling_event;

struct iincomplete_with_modeling_event{
	struct {
		char const* name;
		void* self;
		void (*e)(iincomplete_with_modeling_event* self);

	} in;

	struct {
		char const* name;
		void* self;
		void (*a) (iincomplete_with_modeling_event* self);

	} out;
};

#endif // DEZYNE_IINCOMPLETE_WITH_MODELING_EVENT_H
