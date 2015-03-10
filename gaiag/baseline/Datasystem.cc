// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Datasystem.hh"

namespace dezyne
{
  Datasystem::Datasystem(const dezyne::locator& dezyne_locator)
  : meta{"",reinterpret_cast<component*>(this),0,{reinterpret_cast<component*>(&p),reinterpret_cast<component*>(&c)}}
  , p(dezyne_locator)
  , c(dezyne_locator)
  , port(p.top)
  {
    p.meta.parent = reinterpret_cast<component*>(this);
    p.meta.address = reinterpret_cast<component*>(&p);
    p.meta.name = "p";
    c.meta.parent = reinterpret_cast<component*>(this);
    c.meta.address = reinterpret_cast<component*>(&c);
    c.meta.name = "c";
    connect(c.port, p.bottom);
  }
}
