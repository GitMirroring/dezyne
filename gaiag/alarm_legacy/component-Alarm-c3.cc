// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <boost/make_shared.hpp>
#include <boost/enable_shared_from_this.hpp>

class SingleThreaded: public asd::channels::ISingleThreaded
{
public:
  void processCBs() {std::cout << "SingleThreaded::processCBs" << std::endl;}
};

class LegacyCB: public IAlarmSystem_NI
{
  interface::IConsole& iconsole;
public:
  LegacyCB(interface::IConsole& iconsole)
  : iconsole(iconsole)
  {}
  void Tripped() {iconsole.out.detected();}
  void SwitchedOff() {iconsole.out.deactivated();}
};

class LegacySensor: public WindowSensorComponent
                  , public ISensor
                  , public boost::enable_shared_from_this<LegacySensor>
{
  boost::shared_ptr<asd::channels::ISingleThreaded> st;
  boost::shared_ptr<ISensor_NI> cb;
  interface::ISensor* sensor;
public:
  static boost::shared_ptr<LegacySensor> singleton;

  void set(interface::ISensor& sensor)
  {
    this->sensor = &sensor;
    sensor.out.triggered = boost::bind(&LegacySensor::DetectedMovement, this);
    sensor.out.disabled = boost::bind(&LegacySensor::Deactivated, this);
  }
  void DetectedMovement() {cb->DetectedMovement(); st->processCBs();}
  void Deactivated() {cb->Deactivated(); st->processCBs();}
  void Activate() {sensor->in.enable();}
  void Deactivate() {sensor->in.disable();}
  void GetAPI(boost::shared_ptr<ISensor>* api) {*api = shared_from_this();}
  void RegisterCB(boost::shared_ptr<ISensor_NI> cb) {this->cb = cb;}
  void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> st) {this->st = st;}
};

boost::shared_ptr<LegacySensor> LegacySensor::singleton;

boost::shared_ptr<SensorInterface> WindowSensorComponent::GetInstance()
{
  if(not LegacySensor::singleton)
    LegacySensor::singleton = boost::make_shared<LegacySensor>();
  return LegacySensor::singleton;
}
void WindowSensorComponent::ReleaseInstance() {LegacySensor::singleton.reset();}


class LegacySiren: public SirenComponent
                 , public ISiren
                 , public boost::enable_shared_from_this<LegacySiren>
{
  interface::ISiren* siren;
public:
  static boost::shared_ptr<LegacySiren> singleton;

  void set(interface::ISiren& siren) {this->siren = &siren;}
  void TurnOn() {siren->in.turnon();}
  void TurnOff() {siren->in.turnoff();}
  void GetAPI(boost::shared_ptr<ISiren>* api) {*api = shared_from_this();}
};

boost::shared_ptr<LegacySiren> LegacySiren::singleton;

boost::shared_ptr<SirenInterface> SirenComponent::GetInstance()
{
  if(not LegacySiren::singleton)
    LegacySiren::singleton = boost::make_shared<LegacySiren>();
  return LegacySiren::singleton;
}
void SirenComponent::ReleaseInstance() {LegacySiren::singleton.reset();}

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
    a->RegisterCB(boost::make_shared<SingleThreaded>());

    LegacySensor::singleton->set(sensor);
    LegacySiren::singleton->set(siren);
  }
}
