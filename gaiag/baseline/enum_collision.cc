// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "enum_collision.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  enum_collision::enum_collision(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , i({{"enum_collision","i",this},{0,0,0}})
  {
    i.in.foo = [&] () {
      return call_in(this, std::function<ienum_collision::Retval1::type()>([&] {return this->i_foo(); }), std::make_tuple(&i, "foo", "return"));
    };
    i.in.bar = [&] () {
      return call_in(this, std::function<ienum_collision::Retval2::type()>([&] {return this->i_bar(); }), std::make_tuple(&i, "bar", "return"));
    };
  }

  ienum_collision::Retval1::type enum_collision::i_foo()
  {
    reply_ienum_collision_Retval1 = ienum_collision::Retval1::OK;
    return reply_ienum_collision_Retval1;
  }

  ienum_collision::Retval2::type enum_collision::i_bar()
  {
    reply_ienum_collision_Retval2 = ienum_collision::Retval2::NOK;
    return reply_ienum_collision_Retval2;
  }


}
