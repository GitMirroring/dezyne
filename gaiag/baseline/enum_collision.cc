// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  , i()
  {
    i.in.meta.component = "enum_collision";
    i.in.meta.port = "i";
    i.in.meta.address = this;

    i.in.foo = connect<ienum_collision::Retval1::type>(rt, this,
    boost::function<ienum_collision::Retval1::type()>
    ([this] ()
    {
      trace (i, "foo");
      auto r = i_foo();
      trace_return (i, ienum_collision::Retval1::to_string(r));
      return r;
    }
    ));
    i.in.bar = connect<ienum_collision::Retval2::type>(rt, this,
    boost::function<ienum_collision::Retval2::type()>
    ([this] ()
    {
      trace (i, "bar");
      auto r = i_bar();
      trace_return (i, ienum_collision::Retval2::to_string(r));
      return r;
    }
    ));
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
