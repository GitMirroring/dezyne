// dzn-runtime -- Dezyne runtime library
// Copyright © 2015, 2016, 2019, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2015 Paul Hoogendijk <paul@dezyne.org>
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

#include <dzn/queue.h>

#include <assert.h>

#if DZN_DYNAMIC_QUEUES
#include <dzn/mem.h>
#endif

void
dzn_queue_init (dzn_queue *self)
{
#if DZN_DYNAMIC_QUEUES
  self->head = 0;
  self->tail = 0;
  self->size = 0;
#else /* !DZN_DYNAMIC_QUEUES */
  self->head = self->element;
  self->tail = self->element;
  self->size = 0;
#endif /* !DZN_DYNAMIC_QUEUES */
}

bool
dzn_queue_empty (dzn_queue const *self)
{
  return (!dzn_queue_size (self)) ? true : false;
}

uint8_t
dzn_queue_size (dzn_queue const *self)
{
  return self->size;
}

void
dzn_queue_push (dzn_queue *self, void *e)
{
#if DZN_DYNAMIC_QUEUES
  dzn_node *n = (dzn_node *) dzn_malloc (sizeof (dzn_node));
  n->item = e;
  n->next = 0;

  if (!self->head)
    self->head = n;
  else
    self->tail->next = n;
  self->tail = n;
  self->size++;
#else /* !DZN_DYNAMIC_QUEUES */
  * (self->tail) = * ((dzn_node *)e);
  self->tail++;
  if ((self->tail - self->element) == DZN_QUEUE_SIZE)
    self->tail = self->element;
  self->size++;
  assert (self->size <= DZN_QUEUE_SIZE);
#endif /* !DZN_DYNAMIC_QUEUES */
}

void *
dzn_queue_pop (dzn_queue *self)
{
#if DZN_DYNAMIC_QUEUES
  dzn_node *head;
  void *item;
  assert ((int8_t)self->size);
  head = self->head;
  item = head->item;
  self->head = head->next;
  self->size--;
  dzn_free (head);
  return item;
#else /* !DZN_DYNAMIC_QUEUES */
  dzn_node *res;
  assert (self->size);
  res = self->head;
  self->head++;
  if ((self->head - self->element) == DZN_QUEUE_SIZE)
    self->head = self->element;
  self->size--;
  return res;
#endif /* !DZN_DYNAMIC_QUEUES */
}

void *
dzn_queue_front (dzn_queue const *self)
{
#if DZN_DYNAMIC_QUEUES
  return self->head->item;
#else /* !DZN_DYNAMIC_QUEUES */
  return self->head;
#endif /* !DZN_DYNAMIC_QUEUES */
}

#ifdef DZN_QUEUE_TEST
#include <stdio.h>
int
main (void)
{
  dzn_queue q = {0};
  int8_t a = 1;
  int8_t b = 2;
  int8_t c = 3;
  dzn_queue_push (&q, &a);
  printf ("queue_pop a: %d\n", * (int *)dzn_queue_pop (&q));
  dzn_queue_push (&q, &a);
  dzn_queue_push (&q, &b);
  dzn_queue_push (&q, &c);
  printf ("queue_pop c: %d\n", * (int *)dzn_queue_pop (&q));
  printf ("queue_pop b: %d\n", * (int *)dzn_queue_pop (&q));
  printf ("queue_pop a: %d\n", * (int *)dzn_queue_pop (&q));

  /* expect assert
     dzn_queue_pop (&q); */
  return 0;
}
#endif /* DZN_QUEUE_TEST */
