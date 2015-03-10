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

#include "Siren.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Siren::Siren(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , siren({{"Siren","siren",this},{0,0,0}})
  {
    siren.in.turnon = [&] () {
      call_in(this, [this] {siren_turnon();}, std::make_tuple(&siren, "turnon", "return"));
    };
    siren.in.turnoff = [&] () {
      call_in(this, [this] {siren_turnoff();}, std::make_tuple(&siren, "turnoff", "return"));
    };
  }

  void Siren::siren_turnon()
  {
    {
    }
  }

  void Siren::siren_turnoff()
  {
    {
    }
  }


}
