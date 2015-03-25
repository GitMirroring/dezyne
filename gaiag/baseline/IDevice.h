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

#ifndef DEZYNE_IDEVICE_H
#define DEZYNE_IDEVICE_H

typedef enum {
	IDevice_result_t_OK, IDevice_result_t_NOK
} IDevice_result_t;


typedef struct IDevice IDevice;

struct IDevice{
	struct {
		char const* name;
		void* self;
		int (*initialize)(IDevice* self);
		int (*calibrate)(IDevice* self);
		int (*perform_action1)(IDevice* self);
		int (*perform_action2)(IDevice* self);

	} in;

	struct {
		char const* name;
		void* self;

	} out;
};

#endif // DEZYNE_IDEVICE_H
