// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_CHOICE_HH
#define DEZYNE_CHOICE_HH

#include "IChoice.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct Choice
  {
    dezyne::meta meta;
    runtime& rt;
    struct State
    {
      enum type
      {
        Off, Idle, Busy
      };
      static const char* to_string(type v)
      {
        switch(v)
        {
          case Off: return "State_Off";
          case Idle: return "State_Idle";
          case Busy: return "State_Busy";

        }
        return "";
      }
    };
    Choice::State::type s;
    IChoice c;

    Choice(const locator&);

    private:
    void c_e();
  };
}
#endif // DEZYNE_CHOICE_HH
