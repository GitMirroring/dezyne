// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

/*
 * This is confidential material the contents of which are the property of Verum Software Tools BV.  
 * All reproduction and/or duplication in whole or in part without the written prior consent of 
 * Verum Software Tools BV is strictly forbidden.  Modification of this code is strictly forbidden 
 * and may result in software runtime failure.
 *
 * Modification or removal of this notice in whole or in part is strictly forbidden.
 * Copyright 1998 - 2014 Verum Software Tools BV
 */
#ifndef __ASD_PASSBYVALUE_H__
#define __ASD_PASSBYVALUE_H__

#include <boost/type_traits.hpp>

namespace asd
{
  template <typename T>
  struct value
  {
    typedef typename boost::remove_const<typename boost::remove_reference<T>::type>::type type;
  };
}

#endif
