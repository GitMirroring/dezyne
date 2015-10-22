// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

int main()
{
  dezyne::pump pump;
  int i = 1;
  {
    dezyne::locator l;
    dezyne::runtime rt;
    l.set(rt);
    l.set(pump);
    dezyne::illegal_handler ih;
    ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
    l.set(ih);

    OutParamComp sut(l);
    sut.dzn_meta.name = "sut";


    sut.datasource.in.Init = [&] () {std::clog << "datasource.in.Init" << std::endl; return IMultiStepOutParam::IMultiStepOutParam_Values::Ok;};
    sut.datasource.in.Term = [&] () {std::clog << "datasource.in.Term" << std::endl;};
    sut.datasource.in.GetData = [&] (int& nr) {
      static int r = 0;
      std::clog << "datasource.in.GetData r=" << r << std::endl;
      nr = r++;
      return IMultiStepOutParam::IMultiStepOutParam_Values::Ok;
    };
    sut.datasource.in.RequestData = [&] () {
      std::clog << "datasource.in.RequestData" << std::endl;
    };

    sut.check_bindings();
    sut.dump_tree();
    char s[100];
    pump ([&] {sut.outParam.in.e_out(i);});
    std::clog << "i=" << i << std::endl;

    std::cin.getline (s, sizeof(s));

    pump ([&] {sut.outParam.in.e_out_async(i);});
    pump.and_wait ([&] {sut.datasource.out.ReceiveData(i);});
    std::clog << "i=" << i << std::endl;

#if 0
    pump ([&] {sut.outParam.in.e_inout(i);});
    pump.and_wait ([&] {sut.datasource.out.ReceiveData(i);});
    std::clog << "i=" << i << std::endl;

    pump ([&] {sut.outParam.in.e_inout_async(i);});
    pump.and_wait ([&] {sut.datasource.out.ReceiveData(i);});
    std::clog << "i=" << i << std::endl;

    pump ([&] {sut.outParam.in.e_outdated(i);});
    pump.and_wait ([&] {sut.datasource.out.ReceiveData(i);});
    std::clog << "i=" << i << std::endl;
#endif
  }
  std::clog << "i=" << i << std::endl;
}
