// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#include <iostream>

namespace dezyne
{
  Dataparam::Dataparam(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , mi(0)
  , s(IDataparam::Status::Yes)
  , port({{"Dataparam","port",this},{"","",0}})
  {
    port.in.e0 = [&] () {
      call_in(this, [this] {port_e0();}, std::make_tuple(&port, "e0", "return"));
    };
    port.in.e0r = [&] () {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_e0r();}), std::make_tuple(&port, "e0r", "return"));
    };
    port.in.e = [&] (int i) {
      call_in(this, std::function<void()>([&] {port_e(i);}), std::make_tuple(&port, "e", "return"));
    };
    port.in.er = [&] (int i) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_er(i);}), std::make_tuple(&port, "er", "return"));
    };
    port.in.eer = [&] (int i, int j) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_eer(i,j);}), std::make_tuple(&port, "eer", "return"));
    };
    port.in.eo = [&] (int& i) {
      call_in(this, std::function<void()>([&] {port_eo(i);}), std::make_tuple(&port, "eo", "return"));
    };
    port.in.eoo = [&] (int& i, int& j) {
      call_in(this, std::function<void()>([&] {port_eoo(i,j);}), std::make_tuple(&port, "eoo", "return"));
    };
    port.in.eio = [&] (int i, int& j) {
      call_in(this, std::function<void()>([&] {port_eio(i,j);}), std::make_tuple(&port, "eio", "return"));
    };
    port.in.eio2 = [&] (int& i) {
      call_in(this, std::function<void()>([&] {port_eio2(i);}), std::make_tuple(&port, "eio2", "return"));
    };
    port.in.eor = [&] (int& i) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_eor(i);}), std::make_tuple(&port, "eor", "return"));
    };
    port.in.eoor = [&] (int& i, int& j) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_eoor(i,j);}), std::make_tuple(&port, "eoor", "return"));
    };
    port.in.eior = [&] (int i, int& j) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_eior(i,j);}), std::make_tuple(&port, "eior", "return"));
    };
    port.in.eio2r = [&] (int& i) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return port_eio2r(i);}), std::make_tuple(&port, "eio2r", "return"));
    };
  }

  void Dataparam::port_e0()
  {
    {
      port.out.a6(0, 1, 2, 3, 4, 5);
    }
  }

  IDataparam::Status::type Dataparam::port_e0r()
  {
    {
      port.out.a0();
      reply_IDataparam_Status = IDataparam::Status::Yes;
    }
    return reply_IDataparam_Status;
  }

  void Dataparam::port_e(int i)
  {
    {
      int pi = i;
      {
        IDataparam::Status::type s = funx (pi);
        s = s;
        mi = pi;
        mi = xfunx (pi, pi + pi);
        port.out.a(mi);
        port.out.aa(mi, pi);
      }
    }
  }

  IDataparam::Status::type Dataparam::port_er(int i)
  {
    {
      int pi = i;
      {
        IDataparam::Status::type s = IDataparam::Status::No;
        mi = pi;
        port.out.a(mi);
        port.out.aa(mi, pi);
        if (true)
        {
          reply_IDataparam_Status = IDataparam::Status::Yes;
        }
        else
        {
          reply_IDataparam_Status = s;
        }
      }
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eer(int i, int j)
  {
    {
      IDataparam::Status::type s = IDataparam::Status::No;
      port.out.a(j);
      port.out.aa(j, i);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  void Dataparam::port_eo(int& i)
  {
    {
      i = 234;
    }
  }

  void Dataparam::port_eoo(int& i, int& j)
  {
    {
      i = 123;
      j = 456;
    }
  }

  void Dataparam::port_eio(int i, int& j)
  {
    {
      j = i;
    }
  }

  void Dataparam::port_eio2(int& i)
  {
    {
      int t = i;
      i = t + 123;
    }
  }

  IDataparam::Status::type Dataparam::port_eor(int& i)
  {
    {
      i = 234;
      reply_IDataparam_Status = IDataparam::Status::Yes;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eoor(int& i, int& j)
  {
    {
      i = 123;
      j = 456;
      reply_IDataparam_Status = IDataparam::Status::Yes;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eior(int i, int& j)
  {
    {
      j = i;
      reply_IDataparam_Status = IDataparam::Status::Yes;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type Dataparam::port_eio2r(int& i)
  {
    {
      int t = i;
      i = t + 123;
      reply_IDataparam_Status = IDataparam::Status::Yes;
    }
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
