// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <iostream>
#include <boost/coroutine/all.hpp>

int
main ()
{
  boost::coroutines::symmetric_coroutine<void>::call_type* c0;

  boost::coroutines::symmetric_coroutine<void>::call_type c1
    ([&] (boost::coroutines::symmetric_coroutine<void>::yield_type& yield)
     {
       std::clog << "1.0" << std::endl;
       yield (*c0);
       std::clog << "1.1" << std::endl;
       yield (*c0);
     }
     );

  boost::coroutines::symmetric_coroutine<void>::call_type zero
    ([&] (boost::coroutines::symmetric_coroutine<void>::yield_type& yield)
     {
       c0 = &zero;
       std::clog << "0.0" << std::endl;
       yield (c1);
       std::clog << "0.1" << std::endl;
       yield (c1);
     }
     );

  zero ();
}
