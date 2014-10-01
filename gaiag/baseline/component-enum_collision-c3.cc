// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "component-enum_collision-c3.hh"

void handle_event(void*, const asd::function<void()>&);

template <typename R>
inline asd::function<R()> connect(void*, const asd::function<R()>& event)
{
  return event;
}

template <>
inline asd::function<void()> connect<void>(void* scope, const asd::function<void()>& event)
{
  return asd::bind(handle_event, scope, event);
}

namespace component
{
  enum_collision::enum_collision()
  : po_i()
  {
    po_i.in.foo = connect<interface::ienum_collision::Retval1::type>(this, asd::bind<interface::ienum_collision::Retval1::type>(&enum_collision::po_i_foo, this));
    po_i.in.bar = connect<interface::ienum_collision::Retval2::type>(this, asd::bind<interface::ienum_collision::Retval2::type>(&enum_collision::po_i_bar, this));
  }

  interface::ienum_collision::Retval1::type enum_collision::po_i_foo()
  {
    std::cout << "enum_collision.po_i_foo" << std::endl;
    reply_ienum_collision_Retval1 = interface::ienum_collision::Retval1::OK;
    return reply_ienum_collision_Retval1;

  }
  interface::ienum_collision::Retval2::type enum_collision::po_i_bar()
  {
    std::cout << "enum_collision.po_i_bar" << std::endl;
    reply_ienum_collision_Retval2 = interface::ienum_collision::Retval2::NOK;
    return reply_ienum_collision_Retval2;

  }



}
