// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "alarmComponent.h"
#include "sirenComponent.h"

#include <boost/make_shared.hpp>

#include <iostream>

struct CB: public ::console_cb
{
  boost::shared_ptr<::console_api> api;
  CB(  boost::shared_ptr<::console_api> api)
  : api(api)
  {}
  void detected()
  {
    std::cout << "console_cb.detected" << std::endl;
  }
  void deactivated()
  {
    std::cout << "console_cb.deactivated" << std::endl;
  }
};

int main()
{

  boost::shared_ptr<::alarmInterface> alarm_system = alarmComponent::GetInstance(123);
  boost::shared_ptr<::console_api> api;
  alarm_system->GetAPI(&api);
  alarm_system->RegisterCB(boost::make_shared<CB>(api));

  api->arm();
  api->disarm();
}
