// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#ifndef DEZYNE_REPLY_REORDER_H
#define DEZYNE_REPLY_REORDER_H

#include "Provides.h"
#include "Requires.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	meta m;
	runtime_sub sub;
	bool first;
	Provides p_;
	Provides* p;
	Requires r_;
	Requires* r;
} reply_reorder;

void reply_reorder_init(reply_reorder* self, locator* dezyne_locator, meta* m);

#endif // DEZYNE_REPLY_REORDER_H
