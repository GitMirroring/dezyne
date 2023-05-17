// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <rob@dezyne.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger@dezyne.org>
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

#ifndef DZN_QUEUE_H
#define DZN_QUEUE_H

#include <dzn/config.h>

#include <stdbool.h>
#include <stdint.h>
#if !DZN_DYNAMIC_QUEUES
#include <dzn/closure.h>
#endif

typedef struct dzn_node dzn_node;
struct dzn_node
{
#if DZN_DYNAMIC_QUEUES
  void *item;
  dzn_node *next;
#else /* !DZN_DYNAMIC_QUEUES */
  dzn_closure item;
#endif /* !DZN_DYNAMIC_QUEUES */
};

typedef struct dzn_queue dzn_queue;
struct dzn_queue
{
  dzn_node *head;
  dzn_node *tail;
  uint8_t size;
#if !DZN_DYNAMIC_QUEUES
  dzn_node element[DZN_QUEUE_SIZE];
#endif /* !DZN_DYNAMIC_QUEUES */
};

void dzn_queue_init (dzn_queue *self);
bool dzn_queue_empty (dzn_queue const *self);
void dzn_queue_push (dzn_queue *self, void *e);
uint8_t dzn_queue_size (dzn_queue const *self);
void *dzn_queue_front (dzn_queue const *self);
void *dzn_queue_pop (dzn_queue *self);

#endif /* DZN_QUEUE_H */
