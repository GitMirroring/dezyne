// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DEZYNE_INJECTED_HH
#define DEZYNE_INJECTED_HH

#include "logger.hh"
#include "middle.hh"
#include "bottom.hh"


#include "itop.hh"


#include "locator.hh"

namespace dezyne
{
  struct Injected
  {
    dezyne::meta dzn_meta;
    logger l;
    dezyne::locator dezyne_local_locator;
    middle m;
    bottom b;

    itop& t;

    Injected(const dezyne::locator&);
    void check_bindings() const;
    void dump_tree() const;
  };
}
#endif // DEZYNE_INJECTED_HH
