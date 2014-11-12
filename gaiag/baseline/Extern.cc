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

#include "Extern.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  Extern::Extern(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , i(0)
  , j()
  , port()
  {
    port.in.e = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&Extern::port_e, this)));
  }

  void Extern::port_e()
  {
    std::cout << "Extern.port_e" << std::endl;
    assert(false);
  }

}
