// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "norm2b.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>


norm2b::norm2b(const dezyne::locator& dezyne_locator)
: dzn_meta{"","norm2b",reinterpret_cast<const dezyne::component*>(this),0,{},{[this]{p1.check_bindings();},[this]{p2.check_bindings();}}}
, dzn_rt(dezyne_locator.get<dezyne::runtime>())
, dzn_locator(dezyne_locator)
, state(State::Idle)
, idle_status()
, running_status()
, p1{{{"p1",this},{"",0}}}
, p2{{{"p2",this},{"",0}}}
{
  dzn_rt.performs_flush(this) = true;
  p1.in.b = [&] (int& s) {
    return dezyne::call_in(this, std::function<Bool::type()>([&] {return p1_b(s);}), std::make_tuple(&p1, "b", "return"));
  };
  p1.in.success = [&] (int s) {
    dezyne::call_in(this, std::function<void()>([&] {p1_success(s);}), std::make_tuple(&p1, "success", "return"));
  };
  p1.in.fail = [&] (int status) {
    dezyne::call_in(this, std::function<void()>([&] {p1_fail(status);}), std::make_tuple(&p1, "fail", "return"));
  };
  p2.in.b = [&] (int& s) {
    return dezyne::call_in(this, std::function<Bool::type()>([&] {return p2_b(s);}), std::make_tuple(&p2, "b", "return"));
  };
  p2.in.success = [&] (int s) {
    dezyne::call_in(this, std::function<void()>([&] {p2_success(s);}), std::make_tuple(&p2, "success", "return"));
  };
  p2.in.fail = [&] (int status) {
    dezyne::call_in(this, std::function<void()>([&] {p2_fail(status);}), std::make_tuple(&p2, "fail", "return"));
  };

}

Bool::type norm2b::p1_b(int& s)
{
  if (this->state == State::Idle)
  {
    this->out_p1 = [&] {
      s = this->idle_status;
    };
    {
      int& status = s;
      this->p1.out.a();
    }

    dzn_rt.handling(this) = false;
    dzn_locator.get<dezyne::pump>().block(&this->p1);
  }
  else if (this->state == State::Running)
  {
    {
      int& statusx = s;
      {
        this->p1.out.a();
        statusx = this->running_status;
        this->state = State::Idle;
        this->reply__Bool = Bool::f;
      }
    }
  }
  return this->reply__Bool;
}

void norm2b::p1_success(int s)
{
  {
    int x = s;
    {
    }
  }
}

void norm2b::p1_fail(int status)
{
  {
    int x = status;
    {
    }
  }
}

Bool::type norm2b::p2_b(int& s)
{
  {
    int& x = s;
    {
      this->p2.out.a();
      this->reply__Bool = Bool::t;
    }
  }
  return this->reply__Bool;
}

void norm2b::p2_success(int s)
{
  if (this->state == State::Idle)
  {
    {
      int status = s;
      {
        this->idle_status = status;
        this->state = State::Running;
        this->reply__Bool = Bool::t;
        this->out_p1();
        this->out_p1 = 0;
        dzn_locator.get<dezyne::pump>().release(&this->p1);
      }
    }
  }
  else if (this->state == State::Running)
  {
    {
      int status = s;
      this->running_status = status;
    }
  }
}

void norm2b::p2_fail(int status)
{
  this->reply__Bool = Bool::f;
  this->out_p1();
  this->out_p1 = 0;
  dzn_locator.get<dezyne::pump>().release(&this->p1);
}


void norm2b::check_bindings() const
{
  dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
}
void norm2b::dump_tree() const
{
  dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
}

