// Dezyne --- Dezyne command line tools
//
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

#ifndef DEZYNE_ICONSOLE_INTERFACE_H
#define DEZYNE_ICONSOLE_INTERFACE_H

#include "asdInterfaces.h"

#include <boost/shared_ptr.hpp>

class IConsole
{
public:
  virtual void SwitchOn() = 0;
  virtual void SwitchOff() = 0;
};

class IConsoleCB
{
public:
  virtual void Tripped() = 0;
  virtual void Deactivated() = 0;
};

class IConsoleInterface
{
public:
  virtual void GetAPI(boost::shared_ptr<IConsole>*) = 0;
  virtual void RegisterCB(boost::shared_ptr<IConsoleCB>) = 0;
  virtual void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded>) = 0;
};
#endif
