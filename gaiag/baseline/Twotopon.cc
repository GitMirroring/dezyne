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

#include "Twotopon.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Twotopon::Twotopon(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , b(false)
  , i()
  {
    i.in.meta.component = "Twotopon";
    i.in.meta.port = "i";
    i.in.meta.address = this;

    i.in.e = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (i, "e");
      i_e();
      trace_return (i, "return");
      return;
    }
    ));
    i.in.t = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (i, "t");
      i_t();
      trace_return (i, "return");
      return;
    }
    ));
  }

  void Twotopon::i_e()
  {
    if (b)
    {
      i.out.a();
    }
    else if (not (b))
    {
      i.out.a();
    }
  }

  void Twotopon::i_t()
  {
    i.out.a();
  }


}
