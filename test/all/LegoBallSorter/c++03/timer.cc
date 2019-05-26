// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "timer.hh"

#include <dzn/locator.hh>
#include <dzn/pump.hh>

size_t timer::s_id = 0;

timer::timer(const dzn::locator& l)
: locator(l)
, skel::timer(l)
, id(s_id++)
{}
void timer::port_create(int ms)
{
  locator.get<dzn::pump>().handle(id, ms, port.out.timeout);
}
void timer::port_cancel()
{
  locator.get<dzn::pump>().remove(id);
}
