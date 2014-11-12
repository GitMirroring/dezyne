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

#include "Sensor.hh"

#include "asdInterfaces.h"

#include "locator.h"
#include "runtime.h"

#include "SensorComponent.h"

#include <boost/make_shared.hpp>

#include <map>

namespace dezyne
{
  struct SingleThreaded
  : public asd::channels::ISingleThreaded
  {
    void processCBs(){}
  };

  static std::map<Sensor*, boost::shared_ptr<ISensorInterface> > g_handwritten ;



  struct SensorCB
    : public ISensorCB
  {
    ::ISensor& port;
    SensorCB(::ISensor& port)
    : port(port)
    {}
    void Triggered(){ port.out.triggered(); }
    void Disabled(){ port.out.disabled(); }
  };
}

Sensor::Sensor(const dezyne::locator& l)
  : rt (l.get<dezyne::runtime>())
{
  boost::shared_ptr<dezyne::ISensorInterface> component = dezyne::SensorComponent::GetInstance() ;
  boost::shared_ptr<dezyne::ISensor> api_sensor;
  component->GetAPI(&api_sensor);

  dezyne::g_handwritten.insert (std::make_pair (this,component));
  component->RegisterCB(boost::make_shared<dezyne::SensorCB>(boost::ref(sensor)));

  component->RegisterCB(boost::make_shared<dezyne::SingleThreaded>()); //fixme
  sensor.in.enable = dezyne::bind(&dezyne::ISensor::Enable,api_sensor);
  sensor.in.disable = dezyne::bind(&dezyne::ISensor::Disable,api_sensor);
}
