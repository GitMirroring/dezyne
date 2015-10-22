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

#include "norm2b.hh"

#include <iostream>

int main()
{
  int data = -1;
  {
    dezyne::locator l;
    dezyne::runtime rt;
    l.set(rt);
    dezyne::illegal_handler ih;
    ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
    l.set(ih);

    norm2b sut(l);
    dezyne::pump pump;
    l.set(pump);
    sut.dzn_meta.name = "sut";

    sut.p1.out.a = [] () {std::clog << "p1.a\n" << std::endl;};
    sut.p2.out.a = [] () {std::clog << "p2.a\n" << std::endl;};

    sut.check_bindings();
    sut.dump_tree();

    std::promise<int> data_promise;

    std::clog << "before pump p1" << std::endl;
    pump ([&] () {
        sut.p1.in.b (data);
        data_promise.set_value (data);
      });
    std::clog << "after pump p1 data=" << data << std::endl;

    pump ([&] () {sut.p2.in.success (3);});
    std::clog << "after pump.and_wait p2 data=" << data_promise.get_future().get() << std::endl;

    pump ([&] () {sut.p2.in.success (6);});
    pump.and_wait ([&] () {sut.p1.in.b (data);});
    std::clog << "after pump.and_wait data=" << data << std::endl;

  }
  std::clog << "after ~pump data=" << data << std::endl;
}
