// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Dataparam.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  Dataparam::Dataparam(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , mi(0)
  , s(IDataparam::Status::Yes)
  , port()
  {
    port.in.e0 = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Dataparam::port_e0, this)));
    port.in.e0r = connect<IDataparam::Status::type>(rt, this, boost::function<IDataparam::Status::type()>(boost::bind<IDataparam::Status::type>(&Dataparam::port_e0r, this)));
    port.in.e = connect<int>(rt, this, boost::function<void(int)>(boost::bind<void>(&Dataparam::port_e, this, _1)));
    port.in.er = connect<IDataparam::Status::type,int>(rt, this, boost::function<IDataparam::Status::type(int)>(boost::bind<IDataparam::Status::type>(&Dataparam::port_er, this, _1)));
    port.in.eer = connect<IDataparam::Status::type,int,int>(rt, this, boost::function<IDataparam::Status::type(int,int)>(boost::bind<IDataparam::Status::type>(&Dataparam::port_eer, this, _1, _2)));
    port.in.eo = connect<int&>(rt, this, boost::function<void(int&)>(boost::bind<void>(&Dataparam::port_eo, this, _1)));
    port.in.eoo = connect<int&,int&>(rt, this, boost::function<void(int&,int&)>(boost::bind<void>(&Dataparam::port_eoo, this, _1, _2)));
    port.in.eio = connect<int,int&>(rt, this, boost::function<void(int,int&)>(boost::bind<void>(&Dataparam::port_eio, this, _1, _2)));
    port.in.eio2 = connect<int&>(rt, this, boost::function<void(int&)>(boost::bind<void>(&Dataparam::port_eio2, this, _1)));
    port.in.eor = connect<IDataparam::Status::type,int&>(rt, this, boost::function<IDataparam::Status::type(int&)>(boost::bind<IDataparam::Status::type>(&Dataparam::port_eor, this, _1)));
    port.in.eoor = connect<IDataparam::Status::type,int&,int&>(rt, this, boost::function<IDataparam::Status::type(int&,int&)>(boost::bind<IDataparam::Status::type>(&Dataparam::port_eoor, this, _1, _2)));
    port.in.eior = connect<IDataparam::Status::type,int,int&>(rt, this, boost::function<IDataparam::Status::type(int,int&)>(boost::bind<IDataparam::Status::type>(&Dataparam::port_eior, this, _1, _2)));
    port.in.eio2r = connect<IDataparam::Status::type,int&>(rt, this, boost::function<IDataparam::Status::type(int&)>(boost::bind<IDataparam::Status::type>(&Dataparam::port_eio2r, this, _1)));
  }

  void Dataparam::port_e0()
  {
    std::cout << "Dataparam.port_e0" << std::endl;
    rt.defer(this, boost::bind(port.out.a6, 0, 1, 2, 3, 4, 5));
  }

  IDataparam::Status::type Dataparam::port_e0r()
  {
    std::cout << "Dataparam.port_e0r" << std::endl;
    rt.defer(this, boost::bind(port.out.a0));
    reply_IDataparam_Status = IDataparam::Status::Yes;
    return reply_IDataparam_Status;
  }

  void Dataparam::port_e(int i)
  {
    std::cout << "Dataparam.port_e" << std::endl;
    {
      int pi = i;
      IDataparam::Status::type s = funx (pi);
      s = s;
      mi = pi;
      mi = xfunx (pi, pi + pi);
      rt.defer(this, boost::bind(port.out.a, mi));
      rt.defer(this, boost::bind(port.out.aa, mi, pi));
    }
  }

  IDataparam::Status::type Dataparam::port_er(int i)
  {
    std::cout << "Dataparam.port_er" << std::endl;
    {
      int pi = i;
      IDataparam::Status::type s = IDataparam::Status::No;
      mi = pi;
      rt.defer(this, boost::bind(port.out.a, mi));
      rt.defer(this, boost::bind(port.out.aa, mi, pi));
      if (true)
      {
        reply_IDataparam_Status = IDataparam::Status::Yes;
      }
      else
      {
        reply_IDataparam_Status = s;
      }
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eer(int i, int j)
  {
    std::cout << "Dataparam.port_eer" << std::endl;
    IDataparam::Status::type s = IDataparam::Status::No;
    rt.defer(this, boost::bind(port.out.a, j));
    rt.defer(this, boost::bind(port.out.aa, j, i));
    reply_IDataparam_Status = s;
    return reply_IDataparam_Status;
  }

  void Dataparam::port_eo(int& i)
  {
    std::cout << "Dataparam.port_eo" << std::endl;
    i = 234;
  }

  void Dataparam::port_eoo(int& i, int& j)
  {
    std::cout << "Dataparam.port_eoo" << std::endl;
    i = 123;
    j = 456;
  }

  void Dataparam::port_eio(int i, int& j)
  {
    std::cout << "Dataparam.port_eio" << std::endl;
    j = i;
  }

  void Dataparam::port_eio2(int& i)
  {
    std::cout << "Dataparam.port_eio2" << std::endl;
    int t = i;
    i = t + 123;
  }

  IDataparam::Status::type Dataparam::port_eor(int& i)
  {
    std::cout << "Dataparam.port_eor" << std::endl;
    i = 234;
    reply_IDataparam_Status = IDataparam::Status::Yes;
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eoor(int& i, int& j)
  {
    std::cout << "Dataparam.port_eoor" << std::endl;
    i = 123;
    j = 456;
    reply_IDataparam_Status = IDataparam::Status::Yes;
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eior(int i, int& j)
  {
    std::cout << "Dataparam.port_eior" << std::endl;
    j = i;
    reply_IDataparam_Status = IDataparam::Status::Yes;
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eio2r(int& i)
  {
    std::cout << "Dataparam.port_eio2r" << std::endl;
    int t = i;
    i = t + 123;
    reply_IDataparam_Status = IDataparam::Status::Yes;
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::fun()
  {
    return IDataparam::Status::Yes;
  }

  IDataparam::Status::type Dataparam::funx(int xi)
  {
    xi = xi;
    return IDataparam::Status::Yes;
  }

  int Dataparam::xfunx(int xi, int xj)
  {
    return (xi + xj) / 3;
  }

}
