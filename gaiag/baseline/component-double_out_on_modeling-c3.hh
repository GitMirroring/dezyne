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

#ifndef COMPONENT_DOUBLE_OUT_ON_MODELING_HH
#define COMPONENT_DOUBLE_OUT_ON_MODELING_HH

#include "interface-I-c3.hh"
#include "interface-I-c3.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct double_out_on_modeling
  {
    dezyne::runtime& rt;
    struct State
    {
      enum type
      {
        First, Second
      };
    };
    double_out_on_modeling::State::type state;
    interface::I p;
    interface::I r;

    double_out_on_modeling(const dezyne::locator&);
    void p_start();
    void r_foo();
    void r_bar();
  };
}
#endif
