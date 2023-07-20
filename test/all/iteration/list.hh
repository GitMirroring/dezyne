// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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
#ifndef LIST_HH
#define LIST_HH

struct list: public skel::list
{
  int count;
  list(const dzn::locator& locator)
    : skel::list(locator)
    , count(0)
  {}
  void i_step()
  {
    i.dzn_peer->dzn_state = 0;
    if (count++ < 2) i.out.next ();
    else
      {
        count = 0;
        i.out.end ();
      }
  }
};

#endif
