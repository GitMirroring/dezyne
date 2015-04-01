// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Main.hh"

namespace dezyne
{
  Main::Main(const dezyne::locator& dezyne_locator)
  : dzn_meta{"","Main",reinterpret_cast<component*>(this),0,{reinterpret_cast<component*>(&adaptor),reinterpret_cast<component*>(&alarm)},{}}
  , adaptor(dezyne_locator)
  , alarm(dezyne_locator)
  , runner(adaptor.runner)
  {
    adaptor.dzn_meta.parent = reinterpret_cast<component*>(this);
    adaptor.dzn_meta.address = reinterpret_cast<component*>(&adaptor);
    adaptor.dzn_meta.name = "adaptor";
    alarm.dzn_meta.parent = reinterpret_cast<component*>(this);
    alarm.dzn_meta.address = reinterpret_cast<component*>(&alarm);
    alarm.dzn_meta.name = "alarm";
    connect(alarm.console, adaptor.console);
  }

  void Main::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Main::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
