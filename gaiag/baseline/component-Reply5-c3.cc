// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "component-Reply5-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  Reply5::Reply5(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , dummy(false)
  , i()
  , u()
  {
    i.in.done = dezyne::connect<interface::I::Status::type>(rt, this, dezyne::function<interface::I::Status::type()>(dezyne::bind<interface::I::Status::type>(&Reply5::i_done, this)));
  }

  interface::I::Status::type Reply5::i_done()
  {
    std::cout << "Reply5.i_done" << std::endl;
    if (true)
    {
      {
        interface::U::Status::type s = u.in.what ();
        s = u.in.what ();
        if (s == interface::U::Status::Ok)
        {
          interface::I::Status::type s = fun ();
          reply_I_Status = s;
        }
        else
        {
          interface::I::Status::type s = fun_arg (interface::I::Status::No);
          reply_I_Status = s;
        }
      }
    }
    return reply_I_Status;
  }

  interface::I::Status::type Reply5::fun()
  {
    return interface::I::Status::Yes;
  }

  interface::I::Status::type Reply5::fun_arg(interface::I::Status::type s)
  {
    return s;
  }
}
