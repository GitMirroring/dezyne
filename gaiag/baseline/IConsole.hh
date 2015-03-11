// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_ICONSOLE_HH
#define DEZYNE_ICONSOLE_HH

#include "meta.hh"

#include <cassert>

namespace dezyne
{
  struct IConsole
  {

    struct
    {
      std::function<void ()> arm;
      std::function<void ()> disarm;
    } in;

    struct
    {
      std::function<void ()> detected;
      std::function<void ()> deactivated;
    } out;

    port::meta meta;
    inline IConsole(port::meta m) : meta(m) {}

    void check_bindings() const
    {
      if (not in.arm) throw dezyne::binding_error_in(meta, "in.arm");
      if (not in.disarm) throw dezyne::binding_error_in(meta, "in.disarm");

      if (not out.detected) throw dezyne::binding_error_out(meta, "out.detected");
      if (not out.deactivated) throw dezyne::binding_error_out(meta, "out.deactivated");

    }
  };

  inline void connect (IConsole& provided, IConsole& required)
  {
    assert (not required.in.arm);
    assert (not required.in.disarm);

    assert (not provided.out.detected);
    assert (not provided.out.deactivated);

    provided.out = required.out;
    required.in = provided.in;
    provided.meta.requires = required.meta.requires;
    required.meta.provides = provided.meta.provides;
  }

}
#endif // DEZYNE_ICONSOLE_HH
