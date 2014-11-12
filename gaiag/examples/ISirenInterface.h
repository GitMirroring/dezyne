// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_ISIREN_INTERFACE_H
#define DEZYNE_ISIREN_INTERFACE_H

#include <boost/shared_ptr.hpp>

namespace dezyne
{
class ISiren
{
public:
  virtual void Turnon() = 0;
  virtual void Turnoff() = 0;
};

class ISirenInterface
{
public:
  virtual void GetAPI(boost::shared_ptr<ISiren>*) = 0;
};
}
#endif
