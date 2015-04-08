// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DEZYNE_TOP_HH
#define DEZYNE_TOP_HH

#include "meta.hh"

#include <cassert>

namespace dezyne
{
  struct Top
  {

    struct
    {
      std::function<void ()> unguarded;
      std::function<void ()> e;
    } in;

    struct
    {
      std::function<void ()> f;
    } out;

    port::meta meta;
    inline Top(port::meta m) : meta(m) {}

    void check_bindings() const
    {
      if (not in.unguarded) throw dezyne::binding_error_in(meta, "in.unguarded");
      if (not in.e) throw dezyne::binding_error_in(meta, "in.e");

      if (not out.f) throw dezyne::binding_error_out(meta, "out.f");

    }
  };

  inline void connect (Top& provided, Top& required)
  {
    provided.out = required.out;
    required.in = provided.in;
    provided.meta.requires = required.meta.requires;
    required.meta.provides = provided.meta.provides;
  }

}
#endif // DEZYNE_TOP_HH
