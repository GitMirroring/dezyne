// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_REPLY7_HH
#define DEZYNE_REPLY7_HH

#include "IReply7.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct Reply7
  {
    dezyne::meta meta;
    runtime& rt;
    IReply7::E::type reply_IReply7_E;
    IReply7 p;
    IReply7 r;

    Reply7(const locator&);

    private:
    IReply7::E::type p_foo();
    void f();
  };
}
#endif // DEZYNE_REPLY7_HH
