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

#ifndef DEZYNE_GUARDTHREETOPON_H
#define DEZYNE_GUARDTHREETOPON_H

#include "IGuardthreetopon.h"
#include "RGuardthreetopon.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	runtime* rt;
	bool b;
	IGuardthreetopon i_;
	IGuardthreetopon* i;
	RGuardthreetopon r_;
	RGuardthreetopon* r;
} Guardthreetopon;

void Guardthreetopon_init(Guardthreetopon* self, locator* dezyne_locator);

#endif // DEZYNE_GUARDTHREETOPON_H
