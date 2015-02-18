// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_PROVIDES_TWICE_HH
#define DEZYNE_PROVIDES_TWICE_HH

#include "external_provides_twice.hh"


#include "iprovides_once.hh"
#include "iprovides_twice.hh"


namespace dezyne
{
  struct locator;
}

namespace dezyne
{
  struct provides_twice
  {
    dezyne::meta meta;
    external_provides_twice one;

    iprovides_once& i;
    iprovides_twice& ii;

    provides_twice(const dezyne::locator&);
  };
}
#endif // DEZYNE_PROVIDES_TWICE_HH
