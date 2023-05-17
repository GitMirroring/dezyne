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

#include <dzn/list.h>
#include <stdlib.h>

static dzn_list *
dzn_list_create (dzn_list *next, void *data)
{
  dzn_list *cell = malloc (sizeof (dzn_list));
  cell->data = data;
  cell->next = next;
  return cell;
}

static dzn_list *
find_cell (dzn_list *self, void *data)
{
  while (self)
    {
      if (self->data == data)
        return self;
      self = self->next;
    }
  return 0;
}

static dzn_list *
find_cell_predicate (dzn_list *self, dzn_predicate predicate)
{
  while (self)
    {
      if (predicate (self->data))
        return self;
      self = self->next;
    }
  return 0;
}

dzn_list *
dzn_list_cons (void *data, dzn_list *self)
{
  return dzn_list_create (self, data);
}

dzn_list *
dzn_list_data (void *data)
{
  return dzn_list_create (0, data);
}

dzn_list *
dzn_list_append (dzn_list *self, dzn_list *list)
{
  if (!self)
    return list;
  dzn_list *head = self;
  while (head && head->next)
    head = head->next;
  head->next = list;
  return self;
}

int
dzn_list_length (dzn_list *self)
{
  int length = 0;
  while (self)
    {
      length++;
      self = self->next;
    }
  return length;
}

void *
dzn_list_find (dzn_list *self, void *data)
{
  dzn_list *cell = find_cell (self, data);
  if (cell)
    return cell->data;
  return 0;
}

void *
dzn_list_find_predicate (dzn_list *self, dzn_predicate predicate)
{
  dzn_list *cell = find_cell_predicate (self, predicate);
  if (cell)
    return cell->data;
  return 0;
}

void *
dzn_list_delete (dzn_list *self, void *data)
{
  dzn_list *head = self;
  if (head && head->data == data)
    {
      self = head->next;
      free (head);
      return self;
    }
  while (head)
    {
      if (head->next && head->next->data == data)
        {
          dzn_list *cell = head->next;
          head->next = cell->next;
          free (cell);
          return self;
        }
      head = head->next;
    }
  return self;
}

#if DZN_LIST_TEST

#ifdef DZN_LIST_TEST
#define DZN_LIST_DEBUG 1
#endif

#if DZN_LIST_DEBUG
#include <stdio.h>
#define debug(...) fprintf (stderr, __VA_ARGS__)
#else
#define debug(...)
#endif

void
print_list (dzn_list *self)
{
  dzn_list *head = self;
  while (head)
    {
      if (head != self)
        fprintf (stderr, " ");
      fprintf (stderr, "%d", head->data);
      head = head->next;
    }
  fprintf (stderr, "\n");
}

int
main ()
{
  dzn_list *lst = dzn_list_cons ((void *)1, 0);
  print_list (lst);
  lst = dzn_list_cons ((void *)2, lst);
  print_list (lst);
  lst = dzn_list_cons ((void *)3, lst);
  print_list (lst);
  debug ("length: %d\n", dzn_list_length (lst));
  dzn_list *found = dzn_list_find (lst, (void *)1);
  debug ("found: %p\n", found);
  lst = dzn_list_delete (lst, (void *)1);
  debug ("deleted 1\n");
  print_list (lst);
  debug ("length: %d\n", dzn_list_length (lst));
  lst = dzn_list_delete (lst, (void *)3);
  debug ("deleted 3\n");
  print_list (lst);
  debug ("length: %d\n", dzn_list_length (lst));
}
#endif
