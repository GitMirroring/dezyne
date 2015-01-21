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

#ifndef DEZYNE_REPLY2_H
#define DEZYNE_REPLY2_H

#include "I.h"
#include "U.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	runtime* rt;
	bool dummy;
	int reply_I_Status;
	int reply_U_Status;
	I i_;
	I* i;
	U u_;
	U* u;
} Reply2;

void Reply2_init(Reply2* self, locator* dezyne_locator);

#endif // DEZYNE_REPLY2_H
