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

#ifndef DEZYNE_REPLY7_H
#define DEZYNE_REPLY7_H

#include "IReply7.h"
#include "IReply7.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	dzn_meta_t dzn_meta;
	runtime_sub dzn_sub;
	int reply_IReply7_E;
	IReply7 p_;
	IReply7* p;
	IReply7 r_;
	IReply7* r;
} Reply7;

void Reply7_init(Reply7* self, locator* dezyne_locator, dzn_meta_t* dzn_meta);

#endif // DEZYNE_REPLY7_H
