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
#include <list>
#include <dzn/coroutine.hh>

namespace dzn
{
  int coroutine::g_id = 0;
  std::ostream debug(std::clog.rdbuf());
}

int
main ()
{
  dzn::debug << "[" << dzn::thread_id () << "] hello" << std::endl;
  std::list<dzn::coroutine> coroutines;
  dzn::coroutine zero;
  coroutines.emplace_back
    ([&]
     {
       std::clog << "1.0" << std::endl;
       coroutines.front ().yield_to (coroutines.back ());
       std::clog << "1.1" << std::endl;
       coroutines.front ().yield_to (coroutines.back ());
     }
     );
  coroutines.emplace_back
    ([&]
     {
       std::clog << "0.0" << std::endl;
       coroutines.back ().yield_to (coroutines.front ());
       std::clog << "0.1" << std::endl;
       coroutines.back ().yield_to (coroutines.front ());
       zero.release();
     });
  coroutines.back ().call (zero);
  return 0;
}
