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

namespace component
{
  Alarm::Alarm()
  : state(States::States::Disarmed)
  , sounding(false)
  , po_console()
  , po_sensor()
  , po_siren()
  {
    po_console.in.arm = asd::bind(&Alarm::po_console_arm, this);
    po_console.in.disarm = asd::bind(&Alarm::po_console_disarm, this);
    po_sensor.out.triggered = asd::bind(&Alarm::po_sensor_triggered, this);
    po_sensor.out.disabled = asd::bind(&Alarm::po_sensor_disabled, this);
  }

  void Alarm::po_console_arm()
  {
    std::cout << "Alarm.arm" << std::endl;
    if (state == States::Disarmed)
    {
      {
        po_sensor.in.enable();
        state = States::Armed;

      }

    }
    else if (state == States::Armed)
    {
      //illegal
    }
    else if (state == States::Disarming)
    {
      //illegal
    }
    else if (state == States::Triggered)
    {
      //illegal
    }


  }
  void Alarm::po_console_disarm()
  {
    std::cout << "Alarm.disarm" << std::endl;
    if (state == States::Disarmed)
    {
      //illegal
    }
    else if (state == States::Armed)
    {
      {
        po_sensor.in.disable();
        state = States::Disarming;

      }

    }
    else if (state == States::Disarming)
    {
      //illegal
    }
    else if (state == States::Triggered)
    {
      {
        po_sensor.in.disable();
        po_siren.in.turnoff();
        sounding = false;
        state = States::Disarming;

      }

    }


  }

  void Alarm::po_sensor_triggered()
  {
    std::cout << "Alarm.triggered" << std::endl;
    if (state == States::Disarmed)
    {
      //illegal
    }
    else if (state == States::Armed)
    {
      {
        po_console.out.detected();
        po_siren.in.turnon();
        sounding = true;
        state = States::Triggered;

      }

    }
    else if (state == States::Disarming)
    {
      {

      }

    }
    else if (state == States::Triggered)
    {
      //illegal
    }


  }
  void Alarm::po_sensor_disabled()
  {
    std::cout << "Alarm.disabled" << std::endl;
    if (state == States::Disarmed)
    {
      //illegal
    }
    else if (state == States::Armed)
    {
      //illegal
    }
    else if (state == States::Disarming)
    {
      {
        if (sounding)
        {
          po_console.out.deactivated();
          po_siren.in.turnoff();
          state = States::Disarmed;
          sounding = false;

        }
        else
        {
          po_console.out.deactivated();
          state = States::Disarmed;

        }

      }

    }
    else if (state == States::Triggered)
    {
      //illegal
    }


  }







}
