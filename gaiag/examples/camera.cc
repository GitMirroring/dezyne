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

#include "Camera.hh"

#include "Hardware.hh"

namespace dezyne {
  void serve_interrupts();
}

int main()
{
  // create runtime infrastructure
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);

  // create camera component
  dezyne::Camera cam(l);

  // stub unconnected callback functions from camera component
  cam.control.out.focus = []{std::cout << "Driver.control_focus" << std::endl;};
  cam.control.out.image = []{std::cout << "Driver.control_image" << std::endl;};
  cam.control.out.ready = []{std::cout << "Driver.control_ready" << std::endl;};

  // play the example test trace
  cam.control.in.setup();
  dezyne::serve_interrupts();

  cam.control.in.shoot();
  dezyne::serve_interrupts();
}

namespace dezyne
{
  std::map<Hardware*, std::pair<int,bool>> hardware;
  int cnt = 0;
  Hardware::Hardware(const locator& l): rt(l.get<runtime>()) {
    port.in.kick = [this]{port_kick();};
	port.in.cancel = [this]{port_cancel();};
    hardware[this].first = cnt++;
    hardware[this].second = true;
  }
  void Hardware::port_kick() {
    hardware[this].second = false;
    std::cout << "Hardware["  << hardware[this].first << "].kick"<< std::endl;
  }
  void Hardware::port_cancel() {
    hardware[this].second = true;
    std::cout << "Hardware["  << hardware[this].first << "].cancel"<< std::endl;
  }
  void serve_interrupts() {
    for(auto& h : hardware) {
      if(not h.second.second) {
        h.second.second = true;
        std::cout << "Hardware[" << h.second.first << "].interrupt" << std::endl;
         h.first->port.out.interrupt();
      }
   	}
  }
}
