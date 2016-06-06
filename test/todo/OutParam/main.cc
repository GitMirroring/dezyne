// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/runtime.hh>
#include <dzn/locator.hh>

#include "OutParam.hh"

#include <iostream>
#include <cassert>

int main()
{
  int i = 1;
  int j = 1024;

  dzn::locator l;
  dzn::runtime rt;
  l.set(rt);
  dzn::illegal_handler ih;
  ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
  l.set(ih);

  OutParam sut(l);
  sut.dzn_meta.name = "sut";
  sut.outParam.meta.requires.port = "outParam";
  sut.datasource.meta.provides.port = "datasource";
  sut.reflector.meta.provides.port = "reflector";

  dzn::pump pump;
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
    sut.datasource.out.ReceiveData(j); // Synchronous call-back!
    return IMultiStepOutParam::IMultiStepOutParam_Values::Ok;
  };
  sut.datasource.in.RequestData = [&] () {
    std::clog << "datasource.in.RequestData" << std::endl;
  };
  sut.reflector.in.Ping = [](){
    std::clog << "reflector.in.Ping" << std::endl;
  };

  sut.check_bindings();
  sut.dump_tree();

#define test_synchronous_datapath
#define test_synchrounous_queue_flush
#define test_sub_machines

#ifdef test_sub_machines
    for (int pass = 0; pass < 2; pass++)
    {
      if (pass == 0)
      {
        std::clog << "Testing data-path for main state machine only." << std::endl;
        pump([&]{sut.outParam.in.disable_sub_machines();});
      }
      else if (pass == 1)
      {
        std::clog << "Testing data-path through sub-machines." << std::endl;
        pump([&]{sut.outParam.in.enable_sub_machines();});
      }
      else break;
#else
    {
#endif


#ifdef test_synchronous_datapath
      i = 848;
      j = 4321;
      pump.and_wait([&] {sut.outParam.in.e_out(i);});
      assert(i == 4321);
      std::clog << "e_out: done" << std::endl;

#endif

#ifdef test_synchronous_datapath
      i = 1234;
      j = 4321;
      pump.and_wait([&]{sut.outParam.in.e_out_sync(i);});
      assert(i == 4321);
      std::clog << "e_out_sync: done" << std::endl;
#endif

#if 1
      pump([&] {sut.outParam.in.e_out_async(i);});
      pump.and_wait([&] {sut.datasource.out.ReceiveData(42);});
      assert(i == 42);
      std::clog << "e_out_async: done" << std::endl;
#endif

#ifdef test_synchrounous_queue_flush
      j = 24;
      pump([&] {sut.outParam.in.e_out_sync_async(i);});
      pump.and_wait([&] {sut.reflector.out.Pong();});
      assert(i == 24);
      std::clog << "e_out_sync_async: done" << std::endl;
#endif

#ifdef test_synchronous_datapath
      i = 142;
      j = 1025;
      pump.and_wait([&] {sut.outParam.in.e_inout(i);});
      assert(i == 1025);
      std::clog << "e_inout: done" << std::endl;
#endif

#ifdef test_synchronous_datapath
      i = 1234;
      j = 4321;
      pump.and_wait([&] {sut.outParam.in.e_inout_sync(i);});
      assert(i == 4321);
      std::clog << "e_inout_sync: done" << std::endl;
#endif

#if 1
      pump([&] {sut.outParam.in.e_inout_async(i);});
      pump.and_wait([&] {sut.datasource.out.ReceiveData(123);});
      assert(i == 123);
      std::clog << "e_inout_async: done" << std::endl;
#endif

#ifdef test_synchrounous_queue_flush
      j = 124;
      pump([&] {sut.outParam.in.e_inout_sync_async(i);});
      pump.and_wait([&] {sut.reflector.out.Pong();});
      assert(i == 124);
      std::clog << "e_inout_sync_async: done" << std::endl;
#endif

#ifdef test_synchronous_datapath
      j = 12;
      i = 1234;
      pump.and_wait([&] {sut.outParam.in.e_outdated(i);});
      assert(i == 124);
      std::clog << "e_outdated: done" << std::endl;
#endif
    }

  std::clog << "exit main" << std::endl;
}
