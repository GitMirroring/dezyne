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

#ifndef INTERFACE_INTERFACE_COMPONENT_OVERLOAD_C3_HH
#define INTERFACE_INTERFACE_COMPONENT_OVERLOAD_C3_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace asd
{
  using boost::function;
  using boost::bind;
}

namespace interface
{
  struct interface_component_overload
  {
    struct R
    {
      enum type
      {
        V,
      };
    };

    struct
    {
      asd::function<R::type()> e;
    } in;

    struct
    {
    } out;
  };
}

#endif
