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

#ifndef DEZYNE_GUARDEDREQUIREDILLEGAL_HH
#define DEZYNE_GUARDEDREQUIREDILLEGAL_HH

#include "Top.hh"
#include "Bottom.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct GuardedRequiredIllegal
  {
    dezyne::meta dzn_meta;
    runtime& dzn_rt;
    bool c;
    Top t;
    Bottom b;

    GuardedRequiredIllegal(const locator&);
    void check_bindings() const;
    void dump_tree() const;

    private:
    void t_unguarded();
    void t_e();
    void b_f();
  };
}
#endif // DEZYNE_GUARDEDREQUIREDILLEGAL_HH
