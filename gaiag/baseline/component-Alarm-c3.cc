// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  : state(Disarmed)
  , sounding(false)
  , po_console()
  , po_sensor()
  , po_siren()
  {
    po_console.in.arm = asd::bind(&Alarm::arm, this);
    po_console.in.disarm = asd::bind(&Alarm::disarm, this);
    po_sensor.out.triggered = asd::bind(&Alarm::triggered, this);
    po_sensor.out.disabled = asd::bind(&Alarm::disabled, this);
  }

  void Alarm::arm()
  {
    std::cout << "Alarm.arm" << std::endl;
    if (state == Disarmed)
    {
      {
        po_sensor.in.enable();
        state = Armed;

      }

    }
    else if (state == Armed)
    {
      //illegal
    }
    else if (state == Disarming)
    {
      //illegal
    }
    else if (state == Triggered)
    {
      //illegal
    }


  }
  void Alarm::disarm()
  {
    std::cout << "Alarm.disarm" << std::endl;
    if (state == Disarmed)
    {
      //illegal
    }
    else if (state == Armed)
    {
      {
        po_sensor.in.disable();
        state = Disarming;

      }

    }
    else if (state == Disarming)
    {
      //illegal
    }
    else if (state == Triggered)
    {
      {
        po_sensor.in.disable();
        po_siren.in.turnoff();
        sounding = false;
        state = Disarming;

      }

    }


  }

  void Alarm::triggered()
  {
    std::cout << "Alarm.triggered" << std::endl;
    if (state == Disarmed)
    {
      //illegal
    }
    else if (state == Armed)
    {
      {
        po_console.out.detected();
        po_siren.in.turnon();
        sounding = true;
        state = Triggered;

      }

    }
    else if (state == Disarming)
    {
      {

      }

    }
    else if (state == Triggered)
    {
      //illegal
    }


  }
  void Alarm::disabled()
  {
    std::cout << "Alarm.disabled" << std::endl;
    if (state == Disarmed)
    {
      //illegal
    }
    else if (state == Armed)
    {
      //illegal
    }
    else if (state == Disarming)
    {
      {
        if (sounding)
        {
          po_console.out.deactivated();
          po_siren.in.turnoff();
          state = Disarmed;
          sounding = false;

        }
        else
        {
          po_console.out.deactivated();
          state = Disarmed;

        }

      }

    }
    else if (state == Triggered)
    {
      //illegal
    }


  }







}
