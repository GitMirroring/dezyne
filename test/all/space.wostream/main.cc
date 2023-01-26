// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
// Copyright © 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
#include "space.wostream.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <sstream>

// https://github.com/google/googletest/commit/0555b0eacbc56df1fd762c6aa87bb84be9e4ce7e
namespace space
{
// The presence of an operator<< here will terminate lexical scope
// lookup straight away (even though it cannot be a match because of its
// argument types).  Thus, the any operator<< call in will not find any
// candidate defined at global scope.
struct lookup_blocker {};
void
operator<< (lookup_blocker, lookup_blocker);
}

namespace space
{
int
test (space::wostream& w)
{
  std::wostringstream wos;
  wos << w.h.in.hello () << std::endl;
  return 0;
}
}

int
main ()
{
  dzn::locator locator;
  dzn::runtime runtime;
  space::wostream w (locator.set (runtime));
  w.dzn_meta.name = "sut";
  w.h.meta.require.name = "h";
  return space::test (w);
}
