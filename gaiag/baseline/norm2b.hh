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

#ifndef NORM2B_HH
#define NORM2B_HH

#include "inorm2b.hh"
#include "inorm2b.hh"


#include "runtime.hh"

namespace dezyne {
  struct locator;
  struct runtime;
}


struct norm2b
{
  dezyne::meta dzn_meta;
  dezyne::runtime& dzn_rt;
  dezyne::locator const& dzn_locator;
#ifndef ENUM__State
#define ENUM__State 1
  struct State
  {
    enum type
    {
      Idle, Running
    };
  };
#endif // ENUM__State
#ifndef ENUM__Bool
#define ENUM__Bool 1
  struct Bool
  {
    enum type
    {
      f, t
    };
  };
#endif // ENUM__Bool
  State::type state;
  int idle_status;
  int running_status;
  Bool::type reply__Bool;
  std::function<void ()> out_p1;
  std::function<void ()> out_p2;
  inorm2b p1;
  inorm2b p2;

  norm2b(const dezyne::locator&);
  void check_bindings() const;
  void dump_tree() const;

  private:
  Bool::type p1_b(int& s);
  void p1_success(int s);
  void p1_fail(int status);
  Bool::type p2_b(int& s);
  void p2_success(int s);
  void p2_fail(int status);
};

#endif // NORM2B_HH
