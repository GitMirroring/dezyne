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

#ifndef RUNTIME_H
#define RUNTIME_H

#include <stdio.h>
#include <stdbool.h>

typedef struct
{
	int dummy;
} runtime;

bool runtime_handling(void* scope);
void runtime_flush(void* scope);
void runtime_defer(void* scope, void *event);
void runtime_handle_event(void* scope, void* event);

#define ASD_LOG(msg) printf("%s\n", msg)

#endif
