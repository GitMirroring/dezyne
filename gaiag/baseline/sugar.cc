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

#include "sugar.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  sugar::sugar(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , s(Enum::False)
  , i()
  {
    i.in.e = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&sugar::i_e, this)));
  }

  void sugar::i_e()
  {
    std::cout << "sugar.i_e" << std::endl;
    if (s == Enum::False)
    if (s == Enum::False)
    rt.defer(this, dezyne::bind(i.out.a));
  }

}
