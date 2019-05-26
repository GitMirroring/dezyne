// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef BOOLC90_H
#define BOOLC90_H
#ifdef __STDC_VERSION__
  #if (__STDC_VERSION__ >= 199901L)  /* C99 or later? */
    #include <stdint.h>
    #include <stdbool.h>
  #else
    #define C90_COMPILER
  #endif /* #if (__STDC_VERSION__ >= 199901L) */
#else
  #define C90_COMPILER
#endif /* __STDC_VERSION__  */


typedef char char_t;

#ifdef C90_COMPILER
  typedef unsigned char uint8_t;
  typedef unsigned int  uint16_t;
  typedef unsigned long uint32_t;
  typedef signed char   int8_t;
  typedef signed int    int16_t;
  typedef signed long   int32_t;

#ifndef __bool_true_false_are_defined
    #ifdef _Bool
        #define bool                        _Bool
    #else
        #define bool                        uint8_t
        #define FALSE 0u
        #define false 0u
        #define TRUE  1u
        #define true  1u
    #endif
    #define __bool_true_false_are_defined   1
#endif

#endif /* C90_COMPILER */
#endif /* BOOLC90_H */
