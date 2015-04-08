// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_REQUIRES_TWICE_HH
#define DEZYNE_REQUIRES_TWICE_HH

#include "irequires_twice.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct requires_twice
  {
    dezyne::meta dzn_meta;
    runtime& dzn_rt;
    irequires_twice p;
    irequires_twice once;
    irequires_twice twice;

    requires_twice(const locator&);
    void check_bindings() const;
    void dump_tree() const;

    private:
    void p_e();
    void once_a();
    void twice_a();
  };
}
#endif // DEZYNE_REQUIRES_TWICE_HH
