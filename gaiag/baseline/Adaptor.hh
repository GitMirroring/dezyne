// Dezyne --- Dezyne command line tools
//
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

#ifndef DEZYNE_ADAPTOR_HH
#define DEZYNE_ADAPTOR_HH

#include "IRun.hh"
#include "IChoice.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct Adaptor
  {
    dezyne::meta meta;
    runtime& rt;
    struct State
    {
      enum type
      {
        Idle, Active, Terminating
      };
      static const char* to_string(type v)
      {
        switch(v)
        {
          case Idle: return "State_Idle";
          case Active: return "State_Active";
          case Terminating: return "State_Terminating";

        }
        return "";
      }
    };
    typedef int Twice;
    Adaptor::State::type state;
    Adaptor::Twice count;
    IRun runner;
    IChoice choice;

    Adaptor(const locator&);

    private:
    void runner_run();
    void choice_a();
  };
}
#endif // DEZYNE_ADAPTOR_HH
