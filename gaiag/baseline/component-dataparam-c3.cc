// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
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

#include "component-dataparam-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  dataparam::dataparam(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , mi(0)
  , s(interface::idataparam::Status::Yes)
  , port()
  {
    port.in.e0 = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&dataparam::port_e0, this)));
    port.in.e0r = dezyne::connect<interface::idataparam::Status::type>(rt, this, dezyne::function<interface::idataparam::Status::type()>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_e0r, this)));
    port.in.e = dezyne::connect<int>(rt, this, dezyne::function<void(int)>(dezyne::bind<void>(&dataparam::port_e, this, _1)));
    port.in.er = dezyne::connect<interface::idataparam::Status::type,int>(rt, this, dezyne::function<interface::idataparam::Status::type(int)>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_er, this, _1)));
    port.in.eer = dezyne::connect<interface::idataparam::Status::type,int,int>(rt, this, dezyne::function<interface::idataparam::Status::type(int,int)>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_eer, this, _1, _2)));
    port.in.eo = dezyne::connect<int&>(rt, this, dezyne::function<void(int&)>(dezyne::bind<void>(&dataparam::port_eo, this, _1)));
    port.in.eoo = dezyne::connect<int&,int&>(rt, this, dezyne::function<void(int&,int&)>(dezyne::bind<void>(&dataparam::port_eoo, this, _1, _2)));
    port.in.eio = dezyne::connect<int,int&>(rt, this, dezyne::function<void(int,int&)>(dezyne::bind<void>(&dataparam::port_eio, this, _1, _2)));
    port.in.eio2 = dezyne::connect<int&>(rt, this, dezyne::function<void(int&)>(dezyne::bind<void>(&dataparam::port_eio2, this, _1)));
    port.in.eor = dezyne::connect<interface::idataparam::Status::type,int&>(rt, this, dezyne::function<interface::idataparam::Status::type(int&)>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_eor, this, _1)));
    port.in.eoor = dezyne::connect<interface::idataparam::Status::type,int&,int&>(rt, this, dezyne::function<interface::idataparam::Status::type(int&,int&)>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_eoor, this, _1, _2)));
    port.in.eior = dezyne::connect<interface::idataparam::Status::type,int,int&>(rt, this, dezyne::function<interface::idataparam::Status::type(int,int&)>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_eior, this, _1, _2)));
    port.in.eio2r = dezyne::connect<interface::idataparam::Status::type,int&>(rt, this, dezyne::function<interface::idataparam::Status::type(int&)>(dezyne::bind<interface::idataparam::Status::type>(&dataparam::port_eio2r, this, _1)));
  }

  void dataparam::port_e0()
  {
    std::cout << "dataparam.port_e0" << std::endl;
    if (true)
    {
      rt.defer(this, dezyne::bind(port.out.a6,0, 1, 2, 3, 4, 5));
    }
  }

  interface::idataparam::Status::type dataparam::port_e0r()
  {
    std::cout << "dataparam.port_e0r" << std::endl;
    if (true)
    ;
    {
      rt.defer(this, dezyne::bind(port.out.a0));
      reply_idataparam_Status = interface::idataparam::Status::Yes;
    }
    return reply_idataparam_Status;
  }

  void dataparam::port_e(int i)
  {
    std::cout << "dataparam.port_e" << std::endl;
    if (true)
    ;
    {
      int pi = i;
      {
        interface::idataparam::Status::type s = funx (pi);
        mi = pi;
        mi = xfunx (pi, pi + mi);
        rt.defer(this, dezyne::bind(port.out.a,mi));
        rt.defer(this, dezyne::bind(port.out.aa,mi, pi));
      }
    }
  }

  interface::idataparam::Status::type dataparam::port_er(int i)
  {
    std::cout << "dataparam.port_er" << std::endl;
    if (true)
    ;
    {
      int pi = i;
      {
        interface::idataparam::Status::type s = interface::idataparam::Status::No;
        mi = pi;
        rt.defer(this, dezyne::bind(port.out.a,mi));
        rt.defer(this, dezyne::bind(port.out.aa,mi, pi));
        reply_idataparam_Status = s;
      }
    }
    return reply_idataparam_Status;
  }

  interface::idataparam::Status::type dataparam::port_eer(int i, int j)
  {
    std::cout << "dataparam.port_eer" << std::endl;
    if (true)
    ;
    {
      interface::idataparam::Status::type s = interface::idataparam::Status::No;
      rt.defer(this, dezyne::bind(port.out.a,j));
      rt.defer(this, dezyne::bind(port.out.aa,j, i));
      reply_idataparam_Status = s;
    }
    return reply_idataparam_Status;
  }

  void dataparam::port_eo(int& i)
  {
    std::cout << "dataparam.port_eo" << std::endl;
    if (true)
    ;
    {
      i = 234;
    }
  }

  void dataparam::port_eoo(int& i, int& j)
  {
    std::cout << "dataparam.port_eoo" << std::endl;
    if (true)
    ;
    {
      i = 123;
      j = 456;
    }
  }

  void dataparam::port_eio(int i, int& j)
  {
    std::cout << "dataparam.port_eio" << std::endl;
    if (true)
    ;
    {
      j = i;
    }
  }

  void dataparam::port_eio2(int& i)
  {
    std::cout << "dataparam.port_eio2" << std::endl;
    if (true)
    ;
    {
      i = i + 123;
    }
  }

  interface::idataparam::Status::type dataparam::port_eor(int& i)
  {
    std::cout << "dataparam.port_eor" << std::endl;
    if (true)
    ;
    {
      i = 234;
      reply_idataparam_Status = interface::idataparam::Status::Yes;
    }
    return reply_idataparam_Status;
  }

  interface::idataparam::Status::type dataparam::port_eoor(int& i, int& j)
  {
    std::cout << "dataparam.port_eoor" << std::endl;
    if (true)
    ;
    {
      i = 123;
      j = 456;
      reply_idataparam_Status = interface::idataparam::Status::Yes;
    }
    return reply_idataparam_Status;
  }

  interface::idataparam::Status::type dataparam::port_eior(int i, int& j)
  {
    std::cout << "dataparam.port_eior" << std::endl;
    if (true)
    ;
    {
      j = i;
      reply_idataparam_Status = interface::idataparam::Status::Yes;
    }
    return reply_idataparam_Status;
  }

  interface::idataparam::Status::type dataparam::port_eio2r(int& i)
  {
    std::cout << "dataparam.port_eio2r" << std::endl;
    if (true)
    ;
    {
      i = i + 123;
      reply_idataparam_Status = interface::idataparam::Status::Yes;
    }
    return reply_idataparam_Status;
  }

  interface::idataparam::Status::type dataparam::fun()
  {
    return interface::idataparam::Status::Yes;
  }

  interface::idataparam::Status::type dataparam::funx(int xi)
  {
    return interface::idataparam::Status::Yes;
  }

  int dataparam::xfunx(int xi, int xj)
  {
    return (xi + xj) / 3;
  }
}
