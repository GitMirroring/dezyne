// dzn-runtime -- Dezyne runtime library
// Copyright © 2023 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef DZN_LIST_H
#define DZN_LIST_H

typedef struct dzn_list dzn_list;
struct dzn_list
{
  void *data;
  dzn_list* next;
};

typedef int (*dzn_predicate) (void*);

dzn_list* dzn_list_cons (void* data, dzn_list* self);
dzn_list* dzn_list_data (void* data);
dzn_list* dzn_list_append (dzn_list* self, dzn_list* list);
int dzn_list_length (dzn_list* self);
void* dzn_list_find (dzn_list* self, void* data);
void* dzn_list_find_predicate (dzn_list* self, dzn_predicate predicate);
void* dzn_list_delete (dzn_list* self, void* data);

#endif /* DZN_LIST_H */
