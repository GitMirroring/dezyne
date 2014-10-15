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

#include "locator.h"
#include "runtime.h"

namespace dezyne {
  template <typename R, bool checked>
  inline R valued_helper(runtime& rt, void* scope, const function<R()>& event)
  {
    bool& handle = rt.handling(scope);
    if(checked and handle) throw std::logic_error("a valued event cannot be deferred");

    runtime::scoped_value<bool> sv(handle, true);
    R tmp = event();
    if(not sv.initial)
    {
      rt.flush(scope);
    }
    return tmp;
  }

  template <typename R>
  inline function<R()> connect_in(runtime& rt, void* scope, const function<R()>& event)
  {
    return bind(valued_helper<R,false>, boost::ref(rt), scope, event);
  }

  template <>
  inline function<void()> connect_in<void>(runtime& rt, void* scope, const function<void()>& event)
  {
    return bind(&runtime::handle_event, boost::ref(rt), scope, event);
  }

  template <typename R>
  inline function<R()> connect_out(runtime& rt, void* scope, const function<R()>& event)
  {
    return bind(valued_helper<R,true>, boost::ref(rt), scope, event);
  }

  template <>
  inline function<void()> connect_out<void>(runtime& rt, void* scope, const function<void()>& event)
  {
    return bind(&runtime::handle_event, boost::ref(rt), scope, event);
  }
}

namespace component
{
  enum_collision::enum_collision(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , i()
  {
    i.in.foo = dezyne::connect_in<interface::ienum_collision::Retval1::type>(rt, this, dezyne::bind<interface::ienum_collision::Retval1::type>(&enum_collision::i_foo, this));
    i.in.bar = dezyne::connect_in<interface::ienum_collision::Retval2::type>(rt, this, dezyne::bind<interface::ienum_collision::Retval2::type>(&enum_collision::i_bar, this));
  }

  interface::ienum_collision::Retval1::type enum_collision::i_foo()
  {
    std::cout << "enum_collision.i_foo" << std::endl;
    reply_ienum_collision_Retval1 = interface::ienum_collision::Retval1::OK;
    return reply_ienum_collision_Retval1;
  }

  interface::ienum_collision::Retval2::type enum_collision::i_bar()
  {
    std::cout << "enum_collision.i_bar" << std::endl;
    reply_ienum_collision_Retval2 = interface::ienum_collision::Retval2::NOK;
    return reply_ienum_collision_Retval2;
  }

}
