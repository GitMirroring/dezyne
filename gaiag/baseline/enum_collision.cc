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

#include "enum_collision.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  enum_collision::enum_collision(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , i()
  {
    i.in.foo = connect<ienum_collision::Retval1::type>(rt, this, boost::function<ienum_collision::Retval1::type()>(boost::bind<ienum_collision::Retval1::type>(&enum_collision::i_foo, this)));
    i.in.bar = connect<ienum_collision::Retval2::type>(rt, this, boost::function<ienum_collision::Retval2::type()>(boost::bind<ienum_collision::Retval2::type>(&enum_collision::i_bar, this)));
  }

  ienum_collision::Retval1::type enum_collision::i_foo()
  {
    std::cout << "enum_collision.i_foo" << std::endl;
    reply_ienum_collision_Retval1 = ienum_collision::Retval1::OK;
    return reply_ienum_collision_Retval1;
  }

  ienum_collision::Retval2::type enum_collision::i_bar()
  {
    std::cout << "enum_collision.i_bar" << std::endl;
    reply_ienum_collision_Retval2 = ienum_collision::Retval2::NOK;
    return reply_ienum_collision_Retval2;
  }


}
