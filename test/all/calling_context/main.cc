// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "calling_context.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

int main(int argc, char* argv[])
{
  dzn::locator locator;
  dzn::runtime runtime;

  std::cin.ignore(std::numeric_limits<std::streamsize>::max());

  calling_context sut(locator.set(runtime));
  sut.dzn_meta.name = "sut";
  sut.h.meta.requires.port = "h";
  sut.w.meta.provides.port = "w";

  sut.w.in.world = [&](int& cc, int i){
    dzn::trace (std::clog, sut.w.meta,"world");
    if(cc == 0){cc = 123;} else {assert(cc == 123); cc = 456;}
    dzn::trace_out (std::clog, sut.w.meta,"return"); std::clog << std::endl;
  };

  int cc = 0;

  sut.h.in.hello(cc, 123);

  assert(cc == 456);
}
