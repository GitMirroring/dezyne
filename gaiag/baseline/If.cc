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

#include "If.hh"

#include "locator.h"
#include "runtime.h"

If::If(const dezyne::locator& dezyne_locator)
: rt(dezyne_locator.get<dezyne::runtime>())
, t(false)
, i()
{
  i.in.a = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&If::i_a, this)));
}

void If::i_a()
{
  std::cout << "If.i_a" << std::endl;
  {
    if (t)
    {
      rt.defer(this, dezyne::bind(i.out.b));
    }
    else
    {
      rt.defer(this, dezyne::bind(i.out.c));
    }
    t = not (t);
  }
}


