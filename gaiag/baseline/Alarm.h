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

#ifndef DEZYNE_ALARM_H
#define DEZYNE_ALARM_H

#include "IConsole.h"
#include "ISensor.h"
#include "ISiren.h"


#include "runtime.h"
#include "locator.h"


typedef struct {
	runtime_sub sub;
	int state;
	bool sounding;
	IConsole console_;
	IConsole* console;
	ISensor sensor_;
	ISensor* sensor;
	ISiren siren_;
	ISiren* siren;
} Alarm;

void Alarm_init(Alarm* self, locator* dezyne_locator);

#endif // DEZYNE_ALARM_H
