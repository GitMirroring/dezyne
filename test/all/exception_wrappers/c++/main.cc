// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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

#include "exception_wrappers_exception_forwarding.hh"

#include <iostream>
#include <stdexcept>

int main()
{
  dzn::runtime r;
  dzn::locator l;

  exception_wrappersWrapper sut(l.set(r));
  sut.impl.dzn_meta.name = "sut";
  sut.impl.h.meta.require.port = "h";
  sut.impl.w.meta.provide.port = "w";

  sut.w.in.hello = [] {throw std::logic_error("foo");};
  sut.h.out.world = [] {throw std::logic_error("bar");};

  try {
    sut.h.in.hello();
  } catch (const std::exception& e) {
    std::clog << "exception." << e.what() << std::endl;
  }
  sut.w.out.world();
}
