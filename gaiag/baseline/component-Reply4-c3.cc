// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Gaiag.
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

#include "component-Reply4-c3.hh"

namespace component
{
  Reply4::Reply4()
  : dummy(false)
  , po_i()
  , po_u()
  {
    po_i.in.done = asd::bind(&Reply4::po_i_done, this);
  }

  interface::I::Status::type Reply4::po_i_done()
  {
    std::cout << "Reply4.po_i_done" << std::endl;
    if (true)
    {
      {
        interface::U::Status::type s = po_u.in.what();
        s = po_u.in.what();
        if (s == interface::U::Status::Ok)
        {
          Status::type v = fun();
          if (v == Status::Yes)
          reply_I_Status = interface::I::Status::Yes;
          else
          reply_I_Status = interface::I::Status::No;

        }
        else
        {
          Status::type v = fun_arg(Status::No);
          if (v == Status::Yes)
          reply_I_Status = interface::I::Status::Yes;
          else
          reply_I_Status = interface::I::Status::No;

        }

      }

    }

    return reply_I_Status;

  }




  Reply4::Status::type Reply4::fun()
  {
    {
      return Status::Yes;

    }

  }
  Reply4::Status::type Reply4::fun_arg(Status::type s)
  {
    {
      return s;

    }

  }



}
