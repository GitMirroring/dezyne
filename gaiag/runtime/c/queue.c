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

#include "queue.h"

#include <assert.h>
#include <stdlib.h>

#include "mem.h"

bool
queue_empty (queue* self)
{
  return queue_size (self) == 0;
}

int
queue_size (queue* self)
{
  return self->size;
}

#include <stdio.h>
void
queue_push (queue* self, void* e)
{
  Node* n = (Node*) dzn_malloc (sizeof (Node));
  n->item = e;
  n->next = 0;
  
  if (!self->head) {
    self->head = n;
  } else {
    self->tail->next = n;
  }
  self->tail = n;
  self->size++;
}

void* 
queue_pop (queue* self)
{
  assert (self->size);
  Node* head = self->head;
  void* item = head->item;
  self->head = head->next;
  self->size--;
  free (head);
  return item;
}

void* 
queue_front (queue* self)
{
  return self->head->item;
}

#ifdef QUEUE_TEST
#include <stdio.h>
int 
main ()
{
  queue q = {0};
  int a = 1;
  int b = 2;
  int c = 3;
  queue_push (&q, &a);
  printf ("queue_pop a: %d\n", *(int*)queue_pop (&q));
  queue_push (&q, &a);
  queue_push (&q, &b);
  queue_push (&q, &c);
  printf ("queue_pop c: %d\n", *(int*)queue_pop (&q));
  printf ("queue_pop b: %d\n", *(int*)queue_pop (&q));
  printf ("queue_pop a: %d\n", *(int*)queue_pop (&q));

  // expect assert
  // queue_pop (&q);
  return 0;
}
#endif
