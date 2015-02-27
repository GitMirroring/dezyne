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

#include "proxy.hh"

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

  proxy::proxy(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , top()
  , bottom()
  {
    top.in.meta.component = "proxy";
    top.in.meta.port = "top";
    top.in.meta.address = this;
    bottom.out.meta.component = "proxy";
    bottom.out.meta.port = "bottom";
    bottom.out.meta.address = this;

    top.in.e0 = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (top, "e0");
      top_e0();
      trace_return (top, "e0");
      return;
    }
    ));
    top.in.e0r = connect<IDataparam::Status::type>(rt, this,
    boost::function<IDataparam::Status::type()>
    ([this] ()
    {
      trace (top, "e0r");
      auto r = top_e0r();
      trace_return (top, "e0r");
      return r;
    }
    ));
    top.in.e = connect<int>(rt, this,
    boost::function<void(int)>
    ([this] (int i)
    {
      trace (top, "e");
      top_e(i);
      trace_return (top, "e");
      return;
    }
    ));
    top.in.er = connect<IDataparam::Status::type,int>(rt, this,
    boost::function<IDataparam::Status::type(int)>
    ([this] (int i)
    {
      trace (top, "er");
      auto r = top_er(i);
      trace_return (top, "er");
      return r;
    }
    ));
    top.in.eer = connect<IDataparam::Status::type,int,int>(rt, this,
    boost::function<IDataparam::Status::type(int,int)>
    ([this] (int i, int j)
    {
      trace (top, "eer");
      auto r = top_eer(i,j);
      trace_return (top, "eer");
      return r;
    }
    ));
    top.in.eo = connect<int&>(rt, this,
    boost::function<void(int&)>
    ([this] (int& i)
    {
      trace (top, "eo");
      top_eo(i);
      trace_return (top, "eo");
      return;
    }
    ));
    top.in.eoo = connect<int&,int&>(rt, this,
    boost::function<void(int&,int&)>
    ([this] (int& i, int& j)
    {
      trace (top, "eoo");
      top_eoo(i,j);
      trace_return (top, "eoo");
      return;
    }
    ));
    top.in.eio = connect<int,int&>(rt, this,
    boost::function<void(int,int&)>
    ([this] (int i, int& j)
    {
      trace (top, "eio");
      top_eio(i,j);
      trace_return (top, "eio");
      return;
    }
    ));
    top.in.eio2 = connect<int&>(rt, this,
    boost::function<void(int&)>
    ([this] (int& i)
    {
      trace (top, "eio2");
      top_eio2(i);
      trace_return (top, "eio2");
      return;
    }
    ));
    top.in.eor = connect<IDataparam::Status::type,int&>(rt, this,
    boost::function<IDataparam::Status::type(int&)>
    ([this] (int& i)
    {
      trace (top, "eor");
      auto r = top_eor(i);
      trace_return (top, "eor");
      return r;
    }
    ));
    top.in.eoor = connect<IDataparam::Status::type,int&,int&>(rt, this,
    boost::function<IDataparam::Status::type(int&,int&)>
    ([this] (int& i, int& j)
    {
      trace (top, "eoor");
      auto r = top_eoor(i,j);
      trace_return (top, "eoor");
      return r;
    }
    ));
    top.in.eior = connect<IDataparam::Status::type,int,int&>(rt, this,
    boost::function<IDataparam::Status::type(int,int&)>
    ([this] (int i, int& j)
    {
      trace (top, "eior");
      auto r = top_eior(i,j);
      trace_return (top, "eior");
      return r;
    }
    ));
    top.in.eio2r = connect<IDataparam::Status::type,int&>(rt, this,
    boost::function<IDataparam::Status::type(int&)>
    ([this] (int& i)
    {
      trace (top, "eio2r");
      auto r = top_eio2r(i);
      trace_return (top, "eio2r");
      return r;
    }
    ));
    bottom.out.a0 = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (bottom, "a0");
      bottom_a0();
      return;
    }
    ));
    bottom.out.a = connect<int>(rt, this,
    boost::function<void(int)>
    ([this] (int i)
    {
      trace (bottom, "a");
      bottom_a(i);
      return;
    }
    ));
    bottom.out.aa = connect<int,int>(rt, this,
    boost::function<void(int,int)>
    ([this] (int i, int j)
    {
      trace (bottom, "aa");
      bottom_aa(i,j);
      return;
    }
    ));
    bottom.out.a6 = connect<int,int,int,int,int,int>(rt, this,
    boost::function<void(int,int,int,int,int,int)>
    ([this] (int a0, int a1, int a2, int a3, int a4, int a5)
    {
      trace (bottom, "a6");
      bottom_a6(a0,a1,a2,a3,a4,a5);
      return;
    }
    ));
  }

  void proxy::top_e0()
  {
    bottom.in.e0();
  }

  IDataparam::Status::type proxy::top_e0r()
  {
    {
      IDataparam::Status::type r = bottom.in.e0r ();
      reply_IDataparam_Status = r;
    }
    return reply_IDataparam_Status;
  }

  void proxy::top_e(int i)
  {
    {
      int pi = i;
      bottom.in.e(pi);
    }
  }

  IDataparam::Status::type proxy::top_er(int i)
  {
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
    {
      IDataparam::Status::type r = bottom.in.eer (i, j);
      reply_IDataparam_Status = r;
    }
    return reply_IDataparam_Status;
  }

  void proxy::top_eo(int& i)
  {
    {
      outfunc (i);
    }
  }

  void proxy::top_eoo(int& i, int& j)
  {
    {
      bottom.in.eoo(i, j);
    }
  }

  void proxy::top_eio(int i, int& j)
  {
    {
      bottom.in.eio(i, j);
    }
  }

  void proxy::top_eio2(int& i)
  {
    {
      bottom.in.eio2(i);
    }
  }

  IDataparam::Status::type proxy::top_eor(int& i)
  {
    {
      IDataparam::Status::type s = bottom.in.eor (i);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eoor(int& i, int& j)
  {
    {
      IDataparam::Status::type s = bottom.in.eoor (i, j);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eior(int i, int& j)
  {
    {
      IDataparam::Status::type s = bottom.in.eior (i, j);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  IDataparam::Status::type proxy::top_eio2r(int& i)
  {
    {
      IDataparam::Status::type s = bottom.in.eio2r (i);
      reply_IDataparam_Status = s;
    }
    return reply_IDataparam_Status;
  }

  void proxy::bottom_a0()
  {
    rt.defer(this, [=] { top.out.a0(); });
  }

  void proxy::bottom_a(int i)
  {
    deferfunc (i);
  }

  void proxy::bottom_aa(int i, int j)
  {
    rt.defer(this, [=] { top.out.aa(i, j); });
  }

  void proxy::bottom_a6(int a0, int a1, int a2, int a3, int a4, int a5)
  {
    {
      int A0 = a0;
      int A1 = a1;
      int A2 = a2;
      int A3 = a3;
      int A4 = a4;
      int A5 = a5;
      rt.defer(this, [=] { top.out.a6(A0, A1, A2, A3, A4, A5); });
    }
  }

  void proxy::outfunc(int& i)
  {
    int j = i;
    bottom.in.eo(j);
    i = j;
  }

  void proxy::deferfunc(int i)
  {
    rt.defer(this, [=] { top.out.a(i); });
  }

}
