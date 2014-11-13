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

#include "AlarmSystemComponent.h"

#include <boost/make_shared.hpp>

#include <iostream>

struct CB: public IConsoleCB
{
  boost::shared_ptr<IConsole> api;
  CB(  boost::shared_ptr<IConsole> api)
  : api(api)
  {}
  void Tripped()
  {
    std::cout << "ConsoleCB.Tripped" << std::endl;
  }
  void Deactivated()
  {
    std::cout << "ConsoleCB.Deactivated" << std::endl;
  }
};

int main()
{
  boost::shared_ptr<IConsoleInterface> alarm_system = AlarmSystemComponent::GetInstance();
  boost::shared_ptr<IConsole> api;
  alarm_system->GetAPI(&api);
  alarm_system->RegisterCB(boost::make_shared<CB>(api));

  api->SwitchOn();
  api->SwitchOff();
}
