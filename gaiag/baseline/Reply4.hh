// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#ifndef DEZYNE_REPLY4_HH
#define DEZYNE_REPLY4_HH

#include "I.hh"
#include "U.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct Reply4
  {
    dezyne::meta dzn_meta;
    runtime& dzn_rt;
    struct Status
    {
      enum type
      {
        Yes, No
      };
    };
    bool dummy;
    I::Status::type reply_I_Status;
    U::Status::type reply_U_Status;
    I i;
    U u;

    Reply4(const locator&);
    void check_bindings() const;
    void dump_tree() const;

    private:
    I::Status::type i_done();
    Reply4::Status::type fun();
    Reply4::Status::type fun_arg(Reply4::Status::type s);
  };
}
#endif // DEZYNE_REPLY4_HH
