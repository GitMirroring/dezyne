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

#ifndef DEZYNE_IREPLY7_H
#define DEZYNE_IREPLY7_H

typedef enum {
	IReply7_E_A
} IReply7_E;


typedef struct IReply7 IReply7;

struct IReply7{
	struct {
		char const* name;
		void* self;
		int (*foo)(IReply7* self);

	} in;

	struct {
		char const* name;
		void* self;

	} out;
};

#endif // DEZYNE_IREPLY7_H
