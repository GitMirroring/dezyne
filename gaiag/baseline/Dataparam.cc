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

#include <iostream>

namespace dezyne
{
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << ":" << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
    std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << " return " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << ":" << e << std::endl ;
  }

  Dataparam::Dataparam(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , mi(0)
  , s(IDataparam::Status::Yes)
  , port()
  {
    port.in.meta.component = "Dataparam";
    port.in.meta.port = "port";
    port.in.meta.address = this;

    port.in.e0 = connect<void>(rt, this, 
    boost::function<void()>
    ([this] () 
    { 
      trace (port, "e0");
      port_e0();
      trace_return (port, "e0");
      return ;
    }
    ));
    port.in.e0r = connect<IDataparam::Status::type>(rt, this, 
    boost::function<IDataparam::Status::type()>
    ([this] () 
    { 
      trace (port, "e0r");
      auto r = port_e0r();
      trace_return (port, "e0r");
      return r;
    }
    ));
    port.in.e = connect<int>(rt, this, 
    boost::function<void(int)>
    ([this] (int i) 
    { 
      trace (port, "e");
      port_e(i);
      trace_return (port, "e");
      return ;
    }
    ));
    port.in.er = connect<IDataparam::Status::type,int>(rt, this, 
    boost::function<IDataparam::Status::type(int)>
    ([this] (int i) 
    { 
      trace (port, "er");
      auto r = port_er(i);
      trace_return (port, "er");
      return r;
    }
    ));
    port.in.eer = connect<IDataparam::Status::type,int,int>(rt, this, 
    boost::function<IDataparam::Status::type(int,int)>
    ([this] (int i, int j) 
    { 
      trace (port, "eer");
      auto r = port_eer(i,j);
      trace_return (port, "eer");
      return r;
    }
    ));
    port.in.eo = connect<int&>(rt, this, 
    boost::function<void(int&)>
    ([this] (int& i) 
    { 
      trace (port, "eo");
      port_eo(i);
      trace_return (port, "eo");
      return ;
    }
    ));
    port.in.eoo = connect<int&,int&>(rt, this, 
    boost::function<void(int&,int&)>
    ([this] (int& i, int& j) 
    { 
      trace (port, "eoo");
      port_eoo(i,j);
      trace_return (port, "eoo");
      return ;
    }
    ));
    port.in.eio = connect<int,int&>(rt, this, 
    boost::function<void(int,int&)>
    ([this] (int i, int& j) 
    { 
      trace (port, "eio");
      port_eio(i,j);
      trace_return (port, "eio");
      return ;
    }
    ));
    port.in.eio2 = connect<int&>(rt, this, 
    boost::function<void(int&)>
    ([this] (int& i) 
    { 
      trace (port, "eio2");
      port_eio2(i);
      trace_return (port, "eio2");
      return ;
    }
    ));
    port.in.eor = connect<IDataparam::Status::type,int&>(rt, this, 
    boost::function<IDataparam::Status::type(int&)>
    ([this] (int& i) 
    { 
      trace (port, "eor");
      auto r = port_eor(i);
      trace_return (port, "eor");
      return r;
    }
    ));
    port.in.eoor = connect<IDataparam::Status::type,int&,int&>(rt, this, 
    boost::function<IDataparam::Status::type(int&,int&)>
    ([this] (int& i, int& j) 
    { 
      trace (port, "eoor");
      auto r = port_eoor(i,j);
      trace_return (port, "eoor");
      return r;
    }
    ));
    port.in.eior = connect<IDataparam::Status::type,int,int&>(rt, this, 
    boost::function<IDataparam::Status::type(int,int&)>
    ([this] (int i, int& j) 
    { 
      trace (port, "eior");
      auto r = port_eior(i,j);
      trace_return (port, "eior");
      return r;
    }
    ));
    port.in.eio2r = connect<IDataparam::Status::type,int&>(rt, this, 
    boost::function<IDataparam::Status::type(int&)>
    ([this] (int& i) 
    { 
      trace (port, "eio2r");
      auto r = port_eio2r(i);
      trace_return (port, "eio2r");
      return r;
    }
    ));
  }

  void Dataparam::port_e0()
  {
    {
      rt.defer(this, [=] { port.out.a6(0, 1, 2, 3, 4, 5); });
    }
  }

  IDataparam::Status::type Dataparam::port_e0r()
  {
    {
      rt.defer(this, [=] { port.out.a0(); });
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
        rt.defer(this, [=] { port.out.a(mi); });
        rt.defer(this, [=] { port.out.aa(mi, pi); });
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
        rt.defer(this, [=] { port.out.a(mi); });
        rt.defer(this, [=] { port.out.aa(mi, pi); });
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
      rt.defer(this, [=] { port.out.a(j); });
      rt.defer(this, [=] { port.out.aa(j, i); });
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
