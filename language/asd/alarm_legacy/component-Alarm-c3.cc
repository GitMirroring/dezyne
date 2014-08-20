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

#include "component-Alarm-c3.hh"

#include "AlarmSystemComponent.h"
#include "WindowSensorComponent.h"
#include "SirenComponent.h"
#include "TimerComponent.h"

#include <boost/make_shared.hpp>
#include <boost/enable_shared_from_this.hpp>

class LegacyCB: public IAlarmSystem_NI
{
  interface::Console& console;
public:
  LegacyCB(interface::Console& console)
  : console(console)
  {}
  void Tripped()
  {
    console.out.detected();
  }
  void SwitchedOff()
  {
    console.out.deactivated();
  }
};

class LegacySensor: public WindowSensorComponent
                  , public ISensor
                  , public boost::enable_shared_from_this<LegacySensor>
{
  boost::shared_ptr<ISensor_NI> cb;
  interface::Sensor* sensor;
public:
  static boost::shared_ptr<LegacySensor> singleton;

  void set(interface::Sensor& sensor)
  {
    this->sensor = &sensor;
    sensor.out.triggered = boost::bind(&ISensor_NI::DetectedMovement, cb);
    sensor.out.disabled = boost::bind(&ISensor_NI::Deactivated, cb);
  }
  void Activate()
  {
    sensor->in.enable();
  }
  void Deactivate()
  {
    sensor->in.disable();
  }
  void GetAPI(boost::shared_ptr<ISensor>* api)
  {
    *api = shared_from_this();
  }
  void RegisterCB(boost::shared_ptr<ISensor_NI> cb)
  {
    this->cb = cb;
  }
  void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded>)
  {
  }
};

boost::shared_ptr<LegacySensor> LegacySensor::singleton;

boost::shared_ptr<SensorInterface> WindowSensorComponent::GetInstance()
{
  if(not LegacySensor::singleton)
  {
    LegacySensor::singleton = boost::make_shared<LegacySensor>();
  }
  return LegacySensor::singleton;
}
void WindowSensorComponent::ReleaseInstance()
{
  LegacySensor::singleton.reset();
}


class LegacySiren: public SirenComponent
                 , public ISiren
                 , public boost::enable_shared_from_this<LegacySiren>
{
public:
  static boost::shared_ptr<LegacySiren> singleton;

  void TurnOn()
  {
  }
  void TurnOff()
  {
  }
  void GetAPI(boost::shared_ptr<ISiren>* api)
  {
    *api = shared_from_this();
  }
};

boost::shared_ptr<LegacySiren> LegacySiren::singleton;

boost::shared_ptr<SirenInterface> SirenComponent::GetInstance()
{
  if(not LegacySiren::singleton)
  {
    LegacySiren::singleton = boost::make_shared<LegacySiren>();
  }
  return LegacySiren::singleton;
}
void SirenComponent::ReleaseInstance()
{
  LegacySiren::singleton.reset();
}


class LegacyTimer: public TimerComponent
                 , public Timer
                 , public boost::enable_shared_from_this<LegacyTimer>
{
  boost::shared_ptr<TimerCB> cb;
public:
  static boost::shared_ptr<LegacyTimer> singleton;
  void create()
  {
  }
  void cancel()
  {
  }
  void GetAPI(boost::shared_ptr<Timer>* api)
  {
    *api = shared_from_this();
  }
  void RegisterCB(boost::shared_ptr<TimerCB> cb)
  {
    this->cb = cb;
  }
  void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded>)
  {
  }
};

boost::shared_ptr<LegacyTimer> LegacyTimer::singleton;

boost::shared_ptr<TimerInterface> TimerComponent::GetInstance()
{
  if(not LegacyTimer::singleton)
  {
    LegacyTimer::singleton = boost::make_shared<LegacyTimer>();
  }
  return LegacyTimer::singleton;
}
void TimerComponent::ReleaseInstance()
{
  LegacyTimer::singleton.reset();
}


namespace component
{
  Alarm::Alarm()
  : console()
  , sensor()
  , siren()
  {
    static boost::shared_ptr<AlarmSystemInterface> a = AlarmSystemComponent::GetInstance();
    boost::shared_ptr<IAlarmSystem> api;
    a->GetAPI(&api);
    console.in.arm = asd::bind(&IAlarmSystem::SwitchOn, api);
    console.in.disarm = asd::bind(&IAlarmSystem::SwitchOff, api);

    boost::shared_ptr<IAlarmSystem_NI> cb = boost::make_shared<LegacyCB>(boost::ref(console));
    a->RegisterCB(cb);

    LegacySensor::singleton->set(sensor);
  }
  void Alarm::arm()
  {
    std::cout << "Alarm::arm" << std::endl;
  }
  void Alarm::disarm()
  {
    std::cout << "Alarm::disarm" << std::endl;
  }
  void Alarm::triggered()
  {
    std::cout << "Alarm::triggered" << std::endl;
  }
  void Alarm::disabled()
  {
    std::cout << "Alarm::disabled" << std::endl;
  }
}
