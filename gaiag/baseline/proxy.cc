// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "proxy.hh"

#include "locator.hh"
#include "runtime.hh"

namespace component
{
  proxy::proxy(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , top()
  , bottom()
  {
    top.in.e0 = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&proxy::top_e0, this)));
    top.in.e0r = dezyne::connect<IDataparam::Status::type>(rt, this, dezyne::function<IDataparam::Status::type()>(dezyne::bind<IDataparam::Status::type>(&proxy::top_e0r, this)));
    top.in.e = dezyne::connect<int>(rt, this, dezyne::function<void(int)>(dezyne::bind<void>(&proxy::top_e, this, _1)));
    top.in.er = dezyne::connect<IDataparam::Status::type,int>(rt, this, dezyne::function<IDataparam::Status::type(int)>(dezyne::bind<IDataparam::Status::type>(&proxy::top_er, this, _1)));
    top.in.eer = dezyne::connect<IDataparam::Status::type,int,int>(rt, this, dezyne::function<IDataparam::Status::type(int,int)>(dezyne::bind<IDataparam::Status::type>(&proxy::top_eer, this, _1, _2)));
    top.in.eo = dezyne::connect<int&>(rt, this, dezyne::function<void(int&)>(dezyne::bind<void>(&proxy::top_eo, this, _1)));
    top.in.eoo = dezyne::connect<int&,int&>(rt, this, dezyne::function<void(int&,int&)>(dezyne::bind<void>(&proxy::top_eoo, this, _1, _2)));
    top.in.eio = dezyne::connect<int,int&>(rt, this, dezyne::function<void(int,int&)>(dezyne::bind<void>(&proxy::top_eio, this, _1, _2)));
    top.in.eio2 = dezyne::connect<int&>(rt, this, dezyne::function<void(int&)>(dezyne::bind<void>(&proxy::top_eio2, this, _1)));
    top.in.eor = dezyne::connect<IDataparam::Status::type,int&>(rt, this, dezyne::function<IDataparam::Status::type(int&)>(dezyne::bind<IDataparam::Status::type>(&proxy::top_eor, this, _1)));
    top.in.eoor = dezyne::connect<IDataparam::Status::type,int&,int&>(rt, this, dezyne::function<IDataparam::Status::type(int&,int&)>(dezyne::bind<IDataparam::Status::type>(&proxy::top_eoor, this, _1, _2)));
    top.in.eior = dezyne::connect<IDataparam::Status::type,int,int&>(rt, this, dezyne::function<IDataparam::Status::type(int,int&)>(dezyne::bind<IDataparam::Status::type>(&proxy::top_eior, this, _1, _2)));
    top.in.eio2r = dezyne::connect<IDataparam::Status::type,int&>(rt, this, dezyne::function<IDataparam::Status::type(int&)>(dezyne::bind<IDataparam::Status::type>(&proxy::top_eio2r, this, _1)));
    bottom.out.a0 = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&proxy::bottom_a0, this)));
    bottom.out.a = dezyne::connect<int>(rt, this, dezyne::function<void(int)>(dezyne::bind<void>(&proxy::bottom_a, this, _1)));
    bottom.out.aa = dezyne::connect<int,int>(rt, this, dezyne::function<void(int,int)>(dezyne::bind<void>(&proxy::bottom_aa, this, _1, _2)));
    bottom.out.a6 = dezyne::connect<int,int,int,int,int,int>(rt, this, dezyne::function<void(int,int,int,int,int,int)>(dezyne::bind<void>(&proxy::bottom_a6, this, _1, _2, _3, _4, _5, _6)));
  }

  void proxy::top_e0()
  {
    std::cout << "proxy.top_e0" << std::endl;
    bottom.in.e0();
  }

  IDataparam::Status::type proxy::top_e0r()
  {
    std::cout << "proxy.top_e0r" << std::endl;
    {
      IDataparam::Status::type r = bottom.in.e0r ();
      reply_IDataparam_Status = r;
    }
    return reply_IDataparam_Status;
  }

  void proxy::top_e(int i)
  {
    std::cout << "proxy.top_e" << std::endl;
    {
      int pi = i;
      bottom.in.e(pi);
    }
  }

  IDataparam::Status::type proxy::top_er(int i)
  {
    std::cout << "proxy.top_er" << std::endl;
    {
      int pi = i;
      {
        IDataparam::Status::type r = bottom.in.er (pi);
        reply_IDataparam_Status = r;
      }
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eer(int i, int j)
  {
    std::cout << "proxy.top_eer" << std::endl;
    {
      IDataparam::Status::type r = bottom.in.eer (i, j);
      reply_IDataparam_Status = r;
    }
    return reply_IDataparam_Status;
  }

  void proxy::top_eo(int& i)
  {
    std::cout << "proxy.top_eo" << std::endl;
    {
      bottom.in.eo(i);
    }
  }

  void proxy::top_eoo(int& i, int& j)
  {
    std::cout << "proxy.top_eoo" << std::endl;
    {
      bottom.in.eoo(i, j);
    }
  }

  void proxy::top_eio(int i, int& j)
  {
    std::cout << "proxy.top_eio" << std::endl;
    {
      bottom.in.eio(i, j);
    }
  }

  void proxy::top_eio2(int& i)
  {
    std::cout << "proxy.top_eio2" << std::endl;
    {
      bottom.in.eio2(i);
    }
  }

  IDataparam::Status::type proxy::top_eor(int& i)
  {
    std::cout << "proxy.top_eor" << std::endl;
    {
      IDataparam::Status::type s = bottom.in.eor (i);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eoor(int& i, int& j)
  {
    std::cout << "proxy.top_eoor" << std::endl;
    {
      IDataparam::Status::type s = bottom.in.eoor (i, j);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eior(int i, int& j)
  {
    std::cout << "proxy.top_eior" << std::endl;
    {
      IDataparam::Status::type s = bottom.in.eior (i, j);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eio2r(int& i)
  {
    std::cout << "proxy.top_eio2r" << std::endl;
    {
      IDataparam::Status::type s = bottom.in.eio2r (i);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  void proxy::bottom_a0()
  {
    std::cout << "proxy.bottom_a0" << std::endl;
    rt.defer(this, dezyne::bind(top.out.a0));
  }

  void proxy::bottom_a(int i)
  {
    std::cout << "proxy.bottom_a" << std::endl;
    rt.defer(this, dezyne::bind(top.out.a,i));
  }

  void proxy::bottom_aa(int i, int j)
  {
    std::cout << "proxy.bottom_aa" << std::endl;
    rt.defer(this, dezyne::bind(top.out.aa,i, j));
  }

  void proxy::bottom_a6(int a0, int a1, int a2, int a3, int a4, int a5)
  {
    std::cout << "proxy.bottom_a6" << std::endl;
    {
      int A0 = a0;
      int A1 = a1;
      int A2 = a2;
      int A3 = a3;
      int A4 = a4;
      int A5 = a5;
      rt.defer(this, dezyne::bind(top.out.a6,A0, A1, A2, A3, A4, A5));
    }
  }

}
