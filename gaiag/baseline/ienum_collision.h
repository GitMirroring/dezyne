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

#ifndef DEZYNE_IENUM_COLLISION_H
#define DEZYNE_IENUM_COLLISION_H

typedef enum {
	ienum_collision_Retval1_OK, ienum_collision_Retval1_NOK
} ienum_collision_Retval1;
typedef enum {
	ienum_collision_Retval2_OK, ienum_collision_Retval2_NOK
} ienum_collision_Retval2;


typedef struct ienum_collision ienum_collision;

struct ienum_collision{
	struct {
		void* self;
		int (*foo)(ienum_collision* self);
		int (*bar)(ienum_collision* self);

	} in;

	struct {
		void* self;

	} out;
};

#endif // DEZYNE_IENUM_COLLISION_H
