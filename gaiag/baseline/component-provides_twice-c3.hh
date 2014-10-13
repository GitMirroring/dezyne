// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
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

#ifndef COMPONENT_PROVIDES_TWICE_HH
#define COMPONENT_PROVIDES_TWICE_HH

#include "component-external_provides_twice-c3.hh"


#include "interface-iprovides_once-c3.hh"
#include "interface-iprovides_twice-c3.hh"


namespace component
{
  struct provides_twice
  {
    external_provides_twice one;

    interface::iprovides_once& i;
    interface::iprovides_twice& ii;

    provides_twice();
  };
}
#endif
