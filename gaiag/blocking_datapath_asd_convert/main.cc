// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Henk Katerberg <henk.katerberg@yahoo.com>
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

#include "runtime.hh"
#include "locator.hh"

#include "OutParamComp.hh"

#include <iostream>
#include <cassert>

// Data path test for converted ASD model OutParam.dm

int main()
{
  int i = 1;
  int j = 1024;
  {
    dezyne::locator l;
    dezyne::runtime rt;
    l.set(rt);
    dezyne::illegal_handler ih;
    ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
    l.set(ih);

    OutParamComp sut(l);
    sut.dzn_meta.name = "sut";

    dezyne::pump pump;
    l.set(pump);

    sut.datasource.in.Init = [&] () {
      std::clog << "datasource.in.Init" << std::endl;
      return IMultiStepOutParam::IMultiStepOutParam_Values::Ok;
    };
    sut.datasource.in.Term = [&] () {std::clog << "datasource.in.Term" << std::endl;};
    sut.datasource.in.GetData = [&] (int& nr) {
      std::clog << "datasource.in.GetData j=" << j << std::endl;
      nr = j;
      return IMultiStepOutParam::IMultiStepOutParam_Values::Ok;
    };
    sut.datasource.in.GetData_SyncOutResult = [&] () {
      std::clog << "datasource.in.GetData_SyncOutResult j=" << j << std::endl;
      sut.datasource.out.ReceiveData(j);
      return IMultiStepOutParam::IMultiStepOutParam_Values::Ok;
    };
    sut.datasource.in.RequestData = [&] () {
      std::clog << "datasource.in.RequestData" << std::endl;
    };

    sut.check_bindings();
    sut.dump_tree();

    //#define test_synchronous_datapath

#ifdef test_synchronous_datapath
    { // Data path test - out parameter through synchronous call stack
      std::promise<int> promise;
      i = 1234;
      j = 4321;
      pump ([&] {
          sut.outParam.in.e_out(i);
          promise.set_value(i);
        });
      assert(promise.get_future().get() == 4321);
    }
#endif

#ifdef test_synchronous_datapath
    { // Data path test - out parameter through synchronous out event
      std::promise<int> promise;
      i = 1234;
      j = 4321;
      pump ([&] {
          sut.outParam.in.e_out_sync(i);
          promise.set_value(i);
        });
      assert(promise.get_future().get() == 4321);
    }
#endif

    { // Data path test - out parameter through asynchronous out event
      std::promise<int> promise;
      i = 1234;
      pump ([&] {sut.outParam.in.e_out_async(i);});
      pump([&] {sut.datasource.out.ReceiveData(42);
          promise.set_value(i);});
      std::clog << "waiting for promise..., expect 42" << std::endl;
      assert(promise.get_future().get() == 42);
    }
    
#ifdef test_synchronous_datapath
    { // Data path test - out parameter through synchronous call stack
      std::promise<int> promise;
      i = 1234;
      j = 1025;
      pump ([&] {sut.outParam.in.e_inout(i);
          promise.set_value(i);
        });
      assert(promise.get_future().get() == 1025);
    }
#endif
    
    { // Data path test - out parameter through synchronous call stack
      std::promise<int> promise;
      i = 1234;
      pump ([&] {sut.outParam.in.e_inout_async(i);});
      pump([&] {sut.datasource.out.ReceiveData(123);
          promise.set_value(i);});
      assert(promise.get_future().get() == 123);
      std::clog << "Oh yeah" << std::endl;
    }

#ifdef test_synchronous_datapath
    { // Data path test - out parameter through synchronous out event
      std::promise<int> promise;
      i = 1234;
      j = 4321;
      pump ([&] {
          sut.outParam.in.e_inout_sync(i);
          promise.set_value(i);
        });
      assert(promise.get_future().get() == 4321);
    }
#endif

#if(0)
    { // Data path test - out parameter through asynchronous out event
      std::promise<int> promise;
      i = 1234;
      j = 4321;
      pump ([&] {
          sut.outParam.in.e_inout_async(i);
          promise.set_value(i);
        });
      assert(promise.get_future().get() == 4321);
    }
#endif

#ifdef test_synchronous_datapath
    { // Out parameter unchanged after reply()
      std::promise<int> promise;
      i = 12;
      pump ([&] {sut.outParam.in.e_outdated(i);
          promise.set_value(i);
        });
      assert(promise.get_future().get() == 12);
    }
#endif

  }
  std::clog << "i=" << i << std::endl;
}
