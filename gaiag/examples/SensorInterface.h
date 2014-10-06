// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef SENSOR_INTERFACE_H
#define SENSOR_INTERFACE_H

#include "asdInterfaces.h"

#include <boost/shared_ptr.hpp>

class Sensor
{
public:
  virtual void enable() = 0;
  virtual void disable() = 0;
};

class SensorCB
{
public:
  virtual void triggered() = 0;
  virtual void disabled() = 0;
};

class SensorInterface
{
public:
  virtual void GetAPI(boost::shared_ptr<Sensor>*) = 0;
  virtual void RegisterCB(boost::shared_ptr<SensorCB>) = 0;
  virtual void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded>) = 0;
};

#endif
