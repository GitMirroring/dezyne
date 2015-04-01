// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "Injected.hh"

namespace dezyne
{
  Injected::Injected(const dezyne::locator& dezyne_locator)
  : dzn_meta{"","Injected",reinterpret_cast<component*>(this),0,{reinterpret_cast<component*>(&m),reinterpret_cast<component*>(&b)},{}}
  , l(dezyne_locator)
  , dezyne_local_locator(dezyne_locator.clone().set(l.log))
  , m(dezyne_local_locator)
  , b(dezyne_local_locator)
  , t(m.t)
  {
    m.dzn_meta.parent = reinterpret_cast<component*>(this);
    m.dzn_meta.address = reinterpret_cast<component*>(&m);
    m.dzn_meta.name = "m";
    b.dzn_meta.parent = reinterpret_cast<component*>(this);
    b.dzn_meta.address = reinterpret_cast<component*>(&b);
    b.dzn_meta.name = "b";
    connect(b.b, m.b);
  }

  void Injected::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Injected::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
