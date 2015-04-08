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
  proxy::proxy(const locator& dezyne_locator)
  : dzn_meta{"","proxy",reinterpret_cast<const component*>(this),0,{},{[this]{top.check_bindings();},[this]{bottom.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , top({{"top",this},{"",0}})
  , bottom({{"",0},{"bottom",this}})
  {
    dzn_rt.performs_flush(this) = true; 
    top.in.e0 = [&] () {
      call_in(this, [this] {top_e0();}, std::make_tuple(&top, "e0", "return"));
    };
    top.in.e0r = [&] () {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_e0r();}), std::make_tuple(&top, "e0r", "return"));
    };
    top.in.e = [&] (int i) {
      call_in(this, std::function<void()>([&] {top_e(i);}), std::make_tuple(&top, "e", "return"));
    };
    top.in.er = [&] (int i) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_er(i);}), std::make_tuple(&top, "er", "return"));
    };
    top.in.eer = [&] (int i, int j) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_eer(i,j);}), std::make_tuple(&top, "eer", "return"));
    };
    top.in.eo = [&] (int& i) {
      call_in(this, std::function<void()>([&] {top_eo(i);}), std::make_tuple(&top, "eo", "return"));
    };
    top.in.eoo = [&] (int& i, int& j) {
      call_in(this, std::function<void()>([&] {top_eoo(i,j);}), std::make_tuple(&top, "eoo", "return"));
    };
    top.in.eio = [&] (int i, int& j) {
      call_in(this, std::function<void()>([&] {top_eio(i,j);}), std::make_tuple(&top, "eio", "return"));
    };
    top.in.eio2 = [&] (int& i) {
      call_in(this, std::function<void()>([&] {top_eio2(i);}), std::make_tuple(&top, "eio2", "return"));
    };
    top.in.eor = [&] (int& i) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_eor(i);}), std::make_tuple(&top, "eor", "return"));
    };
    top.in.eoor = [&] (int& i, int& j) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_eoor(i,j);}), std::make_tuple(&top, "eoor", "return"));
    };
    top.in.eior = [&] (int i, int& j) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_eior(i,j);}), std::make_tuple(&top, "eior", "return"));
    };
    top.in.eio2r = [&] (int& i) {
      return call_in(this, std::function<IDataparam::Status::type()>([&] {return top_eio2r(i);}), std::make_tuple(&top, "eio2r", "return"));
    };
    bottom.out.a0 = [&] () {
      call_out(this, [this] {bottom_a0();}, std::make_tuple(&bottom, "a0", "return"));
    };
    bottom.out.a = [&] (int i) {
      call_out(this, std::function<void()>([&,i] {this->bottom_a(i);}) , std::make_tuple(&bottom, "a", "return"));
    };
    bottom.out.aa = [&] (int i, int j) {
      call_out(this, std::function<void()>([&,i,j] {this->bottom_aa(i,j);}) , std::make_tuple(&bottom, "aa", "return"));
    };
    bottom.out.a6 = [&] (int a0, int a1, int a2, int a3, int a4, int a5) {
      call_out(this, std::function<void()>([&,a0,a1,a2,a3,a4,a5] {this->bottom_a6(a0,a1,a2,a3,a4,a5);}) , std::make_tuple(&bottom, "a6", "return"));
    };

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
    top.out.a0();
  }

  void proxy::bottom_a(int i)
  {
    deferfunc (i);
  }

  void proxy::bottom_aa(int i, int j)
  {
    top.out.aa(i, j);
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
      top.out.a6(A0, A1, A2, A3, A4, A5);
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
    top.out.a(i);
  }

  void proxy::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void proxy::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
