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

#ifndef DEZYNE_IDATAPARAM_H
#define DEZYNE_IDATAPARAM_H

typedef struct IDataparam IDataparam;

typedef enum {
	Status_Yes, Status_No
} Status;


struct IDataparam {
	struct {
		void (*e0)(void* self );
		int (*e0r)(void* self );
		void (*e)(void* self , int i);
		int (*er)(void* self , int i);
		int (*eer)(void* self , int i, int j);
		void (*eo)(void* self , int* i);
		void (*eoo)(void* self , int* i, int* j);
		void (*eio)(void* self , int i, int* j);
		void (*eio2)(void* self , int* i);
		int (*eor)(void* self , int* i);
		int (*eoor)(void* self , int* i, int* j);
		int (*eior)(void* self , int i, int* j);
		int (*eio2r)(void* self , int* i);

		void* self;
	} in;

	struct {
		void (*a0) (void* self );
		void (*a) (void* self , int i);
		void (*aa) (void* self , int i, int j);
		void (*a6) (void* self , int a0, int a1, int a2, int a3, int a4, int a5);

		void* self;
	} out;
};

#endif // DEZYNE_IDATAPARAM_H
