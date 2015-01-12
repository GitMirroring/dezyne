// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_FUNCTION2_HH
#define DEZYNE_FUNCTION2_HH

#include "ifunction2.hh"


namespace dezyne
{
  struct locator;
  struct runtime;

  struct function2
  {
    runtime& rt;
    bool f;
    ifunction2 i;

    function2(const locator&);

    private:
    void i_a();
    void i_b();
    bool vtoggle();
  };
}
#endif // DEZYNE_FUNCTION2_HH
