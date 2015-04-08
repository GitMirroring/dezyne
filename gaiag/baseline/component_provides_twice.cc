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

#include "component_provides_twice.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  component_provides_twice::component_provides_twice(const locator& dezyne_locator)
  : dzn_meta{"","component_provides_twice",reinterpret_cast<const component*>(this),0,{},{[this]{i.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , i({{"i",this},{"",0}})
  {
    dzn_rt.performs_flush(this) = true; 
    i.in.foo = [&] () {
      call_in(this, [this] {i_foo();}, std::make_tuple(&i, "foo", "return"));
    };

  }

  void component_provides_twice::i_foo()
  {
    assert(false);
  }


  void component_provides_twice::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void component_provides_twice::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
