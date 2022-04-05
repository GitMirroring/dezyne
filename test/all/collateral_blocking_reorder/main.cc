// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

#include "collateral_blocking_reorder.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  dzn::locator loc;
  dzn::runtime rt;
  loc.set (rt);

  collateral_blocking_reorder sut(loc);
  sut.dzn_meta.name = "sut";
  sut.r.meta.require.name = "r";
  sut.e.meta.require.name = "e";

  bool once = true;

  sut.r.in.hello = [&]
  {
    std::clog << "sut.block.r.hello -> <external>.r.hello" << std::endl;
    std::thread([&]{
      if(once) {once = false; sut.e.out.world();}
      sut.r.out.world();
    }).detach();
    std::clog << "sut.block.r.return <- <external>.r.return" << std::endl;
  };
  sut.e.in.hello = [&]
  {
    std::clog << "sut.proxy.e.hello -> <external>.e.hello" << std::endl;
    std::clog << "sut.proxy.e.return <- <external>.e.return" << std::endl;
  };

  sut.p.in.hello ();

  dzn::pump& pump = sut.dzn_locator.get<dzn::pump>();
  pump.wait ();
}
