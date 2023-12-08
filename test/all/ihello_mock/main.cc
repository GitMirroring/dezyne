// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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

#include "ihello_mock.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

int
main ()
{
  bool cruel = false;
  bool world = false;
  bool hello = false;

  struct component: public dzn::component
  {
    dzn::meta dzn_meta;
    dzn::runtime dzn_runtime;
    dzn::locator dzn_locator;
    component ()
      : dzn_meta({"ihello_mock","ihello_mock",0,{},{},{}})
      , dzn_runtime ()
      , dzn_locator ()
    {}
  };
  component c;
  ihello_mock port ({{"sut",&port,&c,&c.dzn_meta},{"sut",0,0,0}}, &c);

  port.in.hello = [&]{hello = true; port.out.cruel ();};
  port.out.cruel = [&]{cruel = true;};
  port.out.world = [&]{world = true;};

  port.in.hello ();

  assert (hello);
  assert (cruel);

  port.out.world ();

  assert (world);
}
