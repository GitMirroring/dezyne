// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

#ifndef HARDWARE_HH
#define HARDWARE_HH

#include "simhal.hh"

struct Hardware: public skel::Hardware
{
  static std::map<Hardware*, std::pair<int,bool> > hardware;
  static int cnt;

  Hardware(const dzn::locator&);
  void port_kick();
  void port_cancel();
  static void serve_interrupts();
};

#endif
