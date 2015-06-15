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

#ifndef ITIMER_IMPL_H
#define ITIMER_IMPL_H



typedef struct itimer_impl itimer_impl;

struct itimer_impl{
	struct {
		char const* name;
		void* self;
		void (*create)(itimer_impl* self,uint32_t ms);
		void (*cancel)(itimer_impl* self);

	} in;

	struct {
		char const* name;
		void* self;
		void (*timeout) (itimer_impl* self);

	} out;

};

#endif // ITIMER_IMPL_H
