// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Alarm.hh"

#include "asdInterfaces.h"

#include "locator.hh"
#include "runtime.hh"

#include "AlarmComponent.h"

#include <boost/make_shared.hpp>

#include <map>

struct SingleThreaded
: public asd::channels::ISingleThreaded
{
  void processCBs(){}
};

static std::map<dezyne::Alarm*, boost::shared_ptr<IConsoleInterface> > g_handwritten;



struct ConsoleCB
: public IConsoleCB
{
  dezyne::IConsole& port;
  ConsoleCB(dezyne::IConsole& port)
  : port(port)
  {}
  void Tripped(){ port.out.detected(); }
  void Deactivated(){ port.out.deactivated(); }
};


namespace dezyne
{
  Alarm::Alarm(const locator& l)
  : rt (l.get<runtime>())
  {
    boost::shared_ptr< ::IConsoleInterface> component = ::AlarmComponent::GetInstance() ;
    boost::shared_ptr< ::IConsole> api_console;
    component->GetAPI(&api_console);

    g_handwritten.insert (std::make_pair (this,component));
    component->RegisterCB(boost::make_shared<ConsoleCB>(boost::ref(console)));

    component->RegisterCB(boost::make_shared< ::SingleThreaded>()); //fixme
    console.in.arm = boost::bind(&::IConsole::SwitchOn,api_console);
    console.in.disarm = boost::bind(&::IConsole::SwitchOff,api_console);
  }
}
