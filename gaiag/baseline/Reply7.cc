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

#include "Reply7.hh"

#include "locator.h"
#include "runtime.h"

namespace dezyne
{
  Reply7::Reply7(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p()
  , r()
  {
    p.in.foo = connect<IReply7::E::type>(rt, this, boost::function<IReply7::E::type()>(boost::bind<IReply7::E::type>(&Reply7::p_foo, this)));
  }

  IReply7::E::type Reply7::p_foo()
  {
    std::cout << "Reply7.p_foo" << std::endl;
    f ();
    return reply_IReply7_E;
  }

  void Reply7::f()
  {
    IReply7::E::type v = r.in.foo ();
    reply_IReply7_E = v;
  }

}
