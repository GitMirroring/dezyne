// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "AlarmSystemComp.hh"



#include "asdInterfaces.h"
#include "AlarmSystemComponent.h"

#include"SensorComponent.h"
#include"SirenComponent.h"


#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <boost/bind.hpp>
#include <boost/enable_shared_from_this.hpp>
#include <boost/make_shared.hpp>
#include <boost/ref.hpp>

dzn::locator* g_locator = nullptr;





struct ASDIAlarmSystem_NI: public IAlarmSystem_NI
{
  dzn::IConsole& port;
  ASDIAlarmSystem_NI(dzn::IConsole& port)
  : port(port)
  {}
  void Tripped(){ return port.out.Tripped(); }
  void SwitchedOff(){ return port.out.SwitchedOff(); }

};




/****************************/
struct SensorGlue
: public SensorComponent
, public boost::enable_shared_from_this<SensorGlue>
{//}
boost::shared_ptr<asd::channels::ISingleThreaded> st;

struct ASDISensor: public ISensor
{
  dzn::ISensor & port;
  ASDISensor()
  : port(g_locator->get<dzn::ISensor>())
  {}
  void Activate()
  {
    return (void)port.in.Activate();
  }
  void Deactivate()
  {
    return (void)port.in.Deactivate();
  }

};

void GetAPI(boost::shared_ptr<ISensor>* api)
{
  *api = boost::make_shared<ASDISensor>();
}



void RegisterCB(boost::shared_ptr<ISensor_NI> cb)
{
  auto& port  = g_locator->get<dzn::ISensor>();

  //TODO

  port.out.DetectedMovement = [&,this,cb](){std::clog << port.meta.requires.port << ".DetectedMovement" << std::endl; cb->DetectedMovement(); st->processCBs();};
  port.out.Deactivated = [&,this,cb](){std::clog << port.meta.requires.port << ".Deactivated" << std::endl; cb->Deactivated(); st->processCBs();};

}



void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  this->st  = st;
}

//{
};

boost::shared_ptr<SensorInterface> SensorComponent::GetInstance()
{
  return boost::make_shared<SensorGlue>();
}

void SensorComponent::ReleaseInstance(){}

struct SirenGlue
: public SirenComponent
, public boost::enable_shared_from_this<SirenGlue>
{//}
boost::shared_ptr<asd::channels::ISingleThreaded> st;

struct ASDISiren: public ISiren
{
  dzn::ISiren & port;
  ASDISiren()
  : port(g_locator->get<dzn::ISiren>())
  {}
  void TurnOn()
  {
    return (void)port.in.TurnOn();
  }
  void TurnOff()
  {
    return (void)port.in.TurnOff();
  }

};

void GetAPI(boost::shared_ptr<ISiren>* api)
{
  *api = boost::make_shared<ASDISiren>();
}




void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> st)
{
  this->st  = st;
}

//{
};

boost::shared_ptr<SirenInterface> SirenComponent::GetInstance()
{
  return boost::make_shared<SirenGlue>();
}

void SirenComponent::ReleaseInstance(){}






struct SingleThreaded
: public asd::channels::ISingleThreaded
{
  void processCBs(){}
};

struct call_helper
{
  const dzn::port::meta& meta;
  const char* event;
  std::string reply;
  call_helper(const dzn::port::meta& meta, const char* event)
  : meta(meta)
  , event(event)
  , reply("return")
  {
    std::clog << meta.provides.port << "." << event << std::endl;
  }
  template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
  void operator()(L&& l)
  {
    return l();
  }
  template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
  auto operator()(L&& l) -> decltype(l())
  {
    auto r = l();
    reply = to_string(r);
    return r;
  }
  ~call_helper()
  {
    std::clog << meta.provides.port << "." << reply.c_str() << std::endl;
  }
};


AlarmSystemComp::AlarmSystemComp(dzn::locator& locator)
: dzn_rt(locator.get<dzn::runtime>())
, dzn_locator(locator)
, console({{"console",this,&dzn_meta},{"",0,0}})
, sensor({{"",0,0},{"sensor",this,&dzn_meta}})
, siren({{"",0,0},{"siren",this,&dzn_meta}})
{
  locator.set(console);
  locator.set(sensor);
  locator.set(siren);

  g_locator = &locator;

  component = AlarmSystemComponent::GetInstance();
  boost::shared_ptr<IAlarmSystem> api_console;
  component->GetAPI(&api_console);
  component->RegisterCB(boost::make_shared<ASDIAlarmSystem_NI>(boost::ref(console)));
  component->RegisterCB(boost::make_shared<SingleThreaded>());
  console.in.SwitchOn = [=](){return call_helper(console.meta, "SwitchOn")([=]{return static_cast<::dzn::IConsole::IAlarmSystem_Values::type>(api_console->SwitchOn()-1);});};
  console.in.SwitchOff = [=](){return call_helper(console.meta, "SwitchOff")([=]{api_console->SwitchOff();});};
}

