// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "hello_foreign.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>



foreign::foreign(const dzn::locator& dzn_locator)
: dzn_meta("","foreign",0,dzn::vector())
, dzn_rt(dzn_locator.get<dzn::runtime>())
, dzn_locator(dzn_locator)
, w(dzn::port::meta(dzn::port::meta::detail("w",this,&dzn_meta),dzn::port::meta::detail("",0,0)))
{
  dzn_rt.performs_flush(this) = true;
  dzn::pump* dzn_pump = dzn_locator.try_get<dzn::pump>();

  w.in.world = boost::bind(&dzn::call_in< foreign,::iworld>,this,boost::function< void() > (boost::bind(& foreign:: w_world,this )),boost::make_tuple(& w, "world", "return"));
}

void foreign::w_world()
{
  return;
}
