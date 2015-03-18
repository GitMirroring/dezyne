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

#ifndef QUEUE_H
#define QUEUE_H

#include <stdbool.h>

typedef struct Node {
    void* item;
    struct Node* next;
} Node;

typedef struct {
    Node* head;
    Node* tail;
    int size;
} queue;

bool queue_empty (queue*);
void queue_push (queue*, void*);
int queue_size (queue*);
void* queue_front (queue*);
void* queue_pop (queue*);

#endif // QUEUE_H
