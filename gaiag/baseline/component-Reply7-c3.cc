// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "component-Reply7-c3.hh"

namespace component
{
  Reply7::Reply7()
  : po_p()
  , po_r()
  {
    po_p.in.foo = asd::bind(&Reply7::po_p_foo, this);
  }

  interface::IReply7::E::type Reply7::po_p_foo()
  {
    std::cout << "Reply7.po_p_foo" << std::endl;
    f();
    return reply_IReply7_E;

  }


  interface::IReply7::E::type Reply7::f()
  {
    {
      interface::IReply7::E::type v = po_r.in.foo();
      reply_IReply7_E = v;

    }

  }
}
