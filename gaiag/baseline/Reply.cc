// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Reply.hh"

#include "locator.h"
#include "runtime.h"

Reply::Reply(const dezyne::locator& dezyne_locator)
: rt(dezyne_locator.get<dezyne::runtime>())
, dummy(false)
, i()
, u()
{
  i.in.done = dezyne::connect<I::Status::type>(rt, this, dezyne::function<I::Status::type()>(dezyne::bind<I::Status::type>(&Reply::i_done, this)));
}

I::Status::type Reply::i_done()
{
  std::cout << "Reply.i_done" << std::endl;
  if (true)
  {
    {
      U::Status::type s = u.in.what ();
      if (s == U::Status::Ok)
      {
        reply_I_Status = I::Status::Yes;
      }
      else
      {
        reply_I_Status = I::Status::No;
      }
    }
  }
  return reply_I_Status;
}


