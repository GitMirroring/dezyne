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

#ifndef DEZYNE_REPLY_HH
#define DEZYNE_REPLY_HH

#include "I.hh"
#include "U.hh"


namespace dezyne
{
  struct locator;
  struct runtime;

  struct Reply
  {
    runtime& rt;
    bool dummy;
    I::Status::type reply_I_Status;
    U::Status::type reply_U_Status;
    I i;
    U u;

    Reply(const locator&);
    I::Status::type i_done();
  };
}
#endif // DEZYNE_REPLY_HH
