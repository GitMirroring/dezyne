// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "runtime.hh"
#include "locator.hh"
#include "pump.hh"

#include "Alarm.hh"

#include <functional>
#include <iostream>
#include <map>
#include <string>

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);
  dezyne::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl; throw std::runtime_error("illegal");};
  l.set(ih);

  Alarm alarm(l);
  alarm.dzn_meta.name = "alarm";

  alarm.console.out.detected = []{ std::cout << "console.detected" << std::endl;};
  alarm.sensor.in.enable = []{ std::cout << "sensor.enable" << std::endl;};
  alarm.sensor.in.disable = []{ std::cout << "sensor.disable" << std::endl;};
  alarm.siren.in.turnon = []{ std::cout << "siren.turnon" << std::endl;};
  alarm.siren.in.turnoff = []{ std::cout << "siren.turnoff" << std::endl;};

  alarm.check_bindings();

  std::map<std::string, std::function<void()>> event_map;
  event_map["console.arm"] = alarm.console.in.arm;
  event_map["console.disarm"] = alarm.console.in.disarm;
  event_map["sensor.triggered"] = alarm.sensor.out.triggered;
  event_map["sensor.disabled"] = alarm.sensor.out.disabled;

  dezyne::pump pump;
  l.set(pump);

  std::string event;
  while(std::cin >> event) {
    if (event_map.find(event) != event_map.end()) {
      pump(event_map[event]);
    }
  }
}
