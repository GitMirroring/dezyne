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

#ifndef DEZYNE_SIREN_H
#define DEZYNE_SIREN_H

#include "ISiren.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	dzn_meta_t dzn_meta;
	runtime_sub dzn_sub;
	ISiren siren_;
	ISiren* siren;
} Siren;

void Siren_init(Siren* self, locator* dezyne_locator, dzn_meta_t* dzn_meta);

#endif // DEZYNE_SIREN_H
