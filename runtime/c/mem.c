// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/mem.h>
#include <assert.h>

#if (DZN_MISRA_C_2004==1)
#define MAX_SIZE 1048576
static uint8_t dzn_memory_array[MAX_SIZE];
static uint8_t* current_address = dzn_memory_array;


void*
dzn_calloc (size_t n, size_t size)
{
  uint8_t* res;
  assert(MAX_SIZE + dzn_memory_array - current_address >= n * size);
  res = current_address;

  current_address = &dzn_memory_array[n*size];
  return res;
}

void*
dzn_malloc(size_t size)
{
  return dzn_calloc((size_t) 1, size);
}

void
dzn_free(void* ptr)
{
  /*no freeing, automated */
  return;
}

#else /* !DZN_MISRA_C_2004 */
#include <stdlib.h>
#include <stdio.h>

void*
dzn_calloc (size_t n, size_t size)
{
  void* res;
  res = calloc(n, size);
  if (res==(void*)0)
  {
      assert (0);
  }
  return res;
}

void*
dzn_malloc(size_t size)
{
  return dzn_calloc(1, size);
}

void
dzn_free(void* ptr)
{
  free(ptr);
}
#endif /* DZN_MISRA_C_2004 */
