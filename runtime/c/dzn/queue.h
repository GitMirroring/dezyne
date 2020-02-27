// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
#include <dzn/boolc90.h>
#if DZN_DYNAMIC_QUEUES==0
#include <dzn/closure.h>
#endif

typedef struct Node_t Node;
struct Node_t {
#if DZN_DYNAMIC_QUEUES
    void* item;
    Node* next;
#else /* !DZN_DYNAMIC_QUEUES */
    dzn_closure item;
#endif /* !DZN_DYNAMIC_QUEUES */
};

typedef struct queue_t queue;
struct queue_t{
    Node* head;
    Node* tail;
    uint8_t size;
#if DZN_DYNAMIC_QUEUES==0
    Node element[DZN_QUEUE_SIZE];
#endif /* !DZN_DYNAMIC_QUEUES */
};

void queue_init(queue* self);
bool queue_empty (const queue* self);
void queue_push (queue* self, void* e);
uint8_t queue_size (const queue* self);
void* queue_front (const queue* self);
void* queue_pop (queue* self);

#endif /* DZN_QUEUE_H */
