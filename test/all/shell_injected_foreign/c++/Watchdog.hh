// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

struct Watchdog: public skel::Watchdog
{
  dzn::pump& pump;
  Watchdog (const dzn::locator& locator)
    : skel::Watchdog (locator)
    , pump (locator.get<dzn::pump> ())
  {}
  void w_set ()
  {
    pump.handle (reinterpret_cast<size_t> (this), 1000, [this]
    {
      std::cout << "BEFORE TIMEOUT" << std::endl;
      this->w_timeout ();
      std::cout << "AFTER TIMEOUT" << std::endl;
    });
    std::cout << "TIMERSET" << std::endl;
  }
  void w_cancel ()
  {
    pump.remove (reinterpret_cast<size_t> (this));
  }
};
