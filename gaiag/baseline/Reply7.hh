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

#ifndef COMPONENT_REPLY7_HH
#define COMPONENT_REPLY7_HH

#include "IReply7.hh"
#include "IReply7.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct Reply7
  {
    dezyne::runtime& rt;
    interface::IReply7::E::type reply_IReply7_E;
    interface::IReply7 p;
    interface::IReply7 r;

    Reply7(const dezyne::locator&);
    interface::IReply7::E::type p_foo();
    void f();
  };
}
#endif
