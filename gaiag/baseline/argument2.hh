// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef COMPONENT_ARGUMENT2_HH
#define COMPONENT_ARGUMENT2_HH

#include "I.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct argument2
  {
    dezyne::runtime& rt;
    bool b;
    interface::I i;

    argument2(const dezyne::locator&);
    void i_e();
    bool g(bool ga, bool gb);
  };
}
#endif
