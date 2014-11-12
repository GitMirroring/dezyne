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

#ifndef COMPONENT_DOUBLE_OUT_ON_MODELING_HH
#define COMPONENT_DOUBLE_OUT_ON_MODELING_HH

#include "I.hh"
#include "I.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

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
  I p;
  I r;

  double_out_on_modeling(const dezyne::locator&);
  void p_start();
  void r_foo();
  void r_bar();
};
#endif
