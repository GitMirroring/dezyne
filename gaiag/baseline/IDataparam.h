// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

typedef enum {
	IDataparam_Status_Yes, IDataparam_Status_No
} IDataparam_Status;


typedef struct IDataparam IDataparam;

struct IDataparam{
	struct {
		char const* name;
		void* self;
		void (*e0)(IDataparam* self);
		int (*e0r)(IDataparam* self);
		void (*e)(IDataparam* self,int i);
		int (*er)(IDataparam* self,int i);
		int (*eer)(IDataparam* self,int i, int j);
		void (*eo)(IDataparam* self,int* i);
		void (*eoo)(IDataparam* self,int* i, int* j);
		void (*eio)(IDataparam* self,int i, int* j);
		void (*eio2)(IDataparam* self,int* i);
		int (*eor)(IDataparam* self,int* i);
		int (*eoor)(IDataparam* self,int* i, int* j);
		int (*eior)(IDataparam* self,int i, int* j);
		int (*eio2r)(IDataparam* self,int* i);

	} in;

	struct {
		char const* name;
		void* self;
		void (*a0) (IDataparam* self);
		void (*a) (IDataparam* self,int i);
		void (*aa) (IDataparam* self,int i, int j);
		void (*a6) (IDataparam* self,int a0, int a1, int a2, int a3, int a4, int a5);

	} out;
};

#endif // DEZYNE_IDATAPARAM_H
