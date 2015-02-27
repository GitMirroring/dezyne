// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Sensor.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
    std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << "return" << " -> " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << "return" << std::endl ;
  }

  Sensor::Sensor(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , sensor()
  {
    sensor.in.meta.component = "Sensor";
    sensor.in.meta.port = "sensor";
    sensor.in.meta.address = this;

    sensor.in.enable = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (sensor, "enable");
      sensor_enable();
      trace_return (sensor, "enable");
      return;
    }
    ));
    sensor.in.disable = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (sensor, "disable");
      sensor_disable();
      trace_return (sensor, "disable");
      return;
    }
    ));
  }

  void Sensor::sensor_enable()
  {
    {
    }
  }

  void Sensor::sensor_disable()
  {
    {
    }
  }


}
