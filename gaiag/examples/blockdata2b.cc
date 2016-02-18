// Dezyne --- Dezyne command line tools
//
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "blockdata2b.hh"

#include <iostream>

int main()
{
  int data = -1;
  {
    dzn::locator l;
    dzn::runtime rt;
    l.set(rt);
    dzn::pump pump;
    l.set(pump);
    dzn::illegal_handler ih;
    ih.illegal = [] {std::clog << "illegal" << std::endl; exit(0);};
    l.set(ih);

    blockdata2b sut(l);
    sut.dzn_meta.name = "sut";

    sut.p1.out.a = [] () {std::clog << "p1.a\n" << std::endl;};
    sut.p2.out.a = [] () {std::clog << "p2.a\n" << std::endl;};

    sut.check_bindings();
    sut.dump_tree();

    //sut.p.in.b (data);
    //sut.p.in.r (3);
    std::clog << "before pump p1" << std::endl;
    pump([&] () {sut.p1.in.b (data);});
    std::clog << "after pump p1 data=" << data << std::endl;
    //pump([&] () {sut.p.in.r (3);});
    pump.and_wait ([&] () {sut.p2.in.success (3);});
    std::clog << "after pump_and_wait p2 data=" << data << std::endl;
  }
  std::clog << "after ~pump data=" << data << std::endl;
}
