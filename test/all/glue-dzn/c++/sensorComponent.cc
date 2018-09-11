// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#include "sensorComponent.h"

#include <boost/make_shared.hpp>
#include <iostream>

boost::shared_ptr<sensorInterface>
sensorComponent::GetInstance ()
{
  return boost::make_shared<sensorComponent>();
}

void
sensorComponent::ReleaseInstance ()
{
}

void
sensorComponent::triggered()
{
  std::cout << "sensorComponent::cb->triggered()" << std::endl;
  sensorComponent::cb->triggered();
  std::cout << "sensorComponent::st->processCBs()" << std::endl;
  sensorComponent::st->processCBs();
}

void
sensorComponent::disabled()
{
  std::cout << "sensorComponent::cb->disabled()" << std::endl;
  sensorComponent::cb->disabled();
  std::cout << "sensorComponent::st->processCBs()" << std::endl;
  sensorComponent::st->processCBs();
}

boost::shared_ptr<sensor_cb> sensorComponent::cb;
boost::shared_ptr<asd::channels::ISingleThreaded> sensorComponent::st;
