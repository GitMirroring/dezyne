// Dezyne --- Dezyne command line tools
//
// Copyright © 2018, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2019 Rutger van Beusekom <rutger@dezyne.org>
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

#ifndef FOREIGN_HH
#define FOREIGN_HH

#include <dzn/locator.hh>
#include <dzn/meta.hh>
#include <dzn/runtime.hh>

struct Foreign: public dzn::component
{
  dzn::meta dzn_meta;
  dzn::runtime& dzn_rt;
  dzn::locator const& dzn_locator;
  ::iworld w;
  Foreign(const dzn::locator&);
  friend std::ostream& operator << (std::ostream& os, const Foreign&)  {
    return os;
  }
  private:
  void w_world();
};

#endif // FOREIGN_HH
