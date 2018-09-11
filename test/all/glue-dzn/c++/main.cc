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

#include "alarmComponent.h"
#include "sensorComponent.h"

#include <boost/make_shared.hpp>

#include <iostream>

struct CB: public ::console_cb
         , public asd::channels::ISingleThreaded
{
  boost::shared_ptr<::console_api> api;
  bool do_disarm = false;

  CB(  boost::shared_ptr<::console_api> api)
  : api(api)
  {}
  void detected()
  {
    std::cout << "console_cb.detected" << std::endl;
    do_disarm = true;
  }
  void deactivated()
  {
    std::cout << "console_cb.deactivated" << std::endl;
  }
  void processCBs()
  {
    std::cout << "console_st.processCBs" << std::endl;
    if (do_disarm) {
      do_disarm = false;
      api->disarm();
   }
  }
};

int main()
{
  boost::shared_ptr<::consoleInterface> alarm_system = alarmComponent::GetInstance(123);
  boost::shared_ptr<::console_api> api;
  boost::shared_ptr<::CB> cb;

  alarm_system->GetAPI(&api);
  cb = boost::make_shared<CB>(api);
  alarm_system->RegisterCB((boost::shared_ptr<console_cb>)cb);
  alarm_system->RegisterCB((boost::shared_ptr<asd::channels::ISingleThreaded>)cb);

  api->arm();
  sensorComponent::triggered();
  sensorComponent::disabled();
}
