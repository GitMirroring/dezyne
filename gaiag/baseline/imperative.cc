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

#include "imperative.hh"

#include "locator.h"
#include "runtime.h"

namespace dezyne
{
  imperative::imperative(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , state(States::I)
  , i()
  {
    i.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&imperative::i_e, this)));
  }

  void imperative::i_e()
  {
    std::cout << "imperative.i_e" << std::endl;
    if (state == States::I)
    {
      {
        rt.defer(this, boost::bind(i.out.f));
        rt.defer(this, boost::bind(i.out.g));
        rt.defer(this, boost::bind(i.out.h));
        state = States::II;
      }
    }
    else if (state == States::II)
    {
      {
        state = States::III;
      }
    }
    else if (state == States::III)
    {
      {
        rt.defer(this, boost::bind(i.out.f));
        rt.defer(this, boost::bind(i.out.g));
        rt.defer(this, boost::bind(i.out.g));
        rt.defer(this, boost::bind(i.out.f));
        state = States::IV;
      }
    }
    else if (state == States::IV)
    {
      {
        rt.defer(this, boost::bind(i.out.h));
        state = States::I;
      }
    }
  }


}
