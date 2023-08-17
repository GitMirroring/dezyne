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

#ifndef HELLO0_HH
#define HELLO0_HH

struct Hello0: public skel::Hello0
{
  Hello0 (dzn::locator const &l)
    : skel::Hello0 (l)
  {}
  ihello0::BOOL w_hello () {return ihello0::BOOL::TRUE;}
};

#endif // HELLO0_HH
