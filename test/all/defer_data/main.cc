// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include "defer_data.hh"

#include <dzn/locator.hh>
#include <dzn/pump.hh>
#include <dzn/runtime.hh>

std::string
read ()
{
  std::string str;
  {
    std::string line;
    while (std::cin >> line)
      str += (str.empty () ? "" : "\n") + line;
  }
  return str;
}

int
main (int argc, char **argv)
{
  if (argv + argc != std::find_if (argv + 1,
                                   argv + argc,
                                   [] (char const* s)
                                   {return s == std::string ("--debug");}))
    dzn::debug.rdbuf (std::clog.rdbuf ());

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  defer_data sut (locator);
  dzn::pump pump;
  locator.set(pump);

  sut.dzn_meta.name = "sut";

  sut.h.meta.require.name = "h";
  sut.h.meta.require.port = &sut.h;

  sut.h.out.world = [&] (int) {};

  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "h.hello\nh.return\nh.hi\nh.return\n<defer>\nh.world")
  {
    pump ([&] {sut.h.in.hello (0);});
    pump ([&] {sut.h.in.hi (0);});
  }
  else if (trace == "h.hello\nh.return\nh.cruel\nh.return\n<defer>\nh.world")
  {
    pump ([&] {sut.h.in.hello (0);});
    pump ([&] {sut.h.in.cruel (1);});
  }
  else
  {
    std::clog << "missing trace" << std::endl;
    return 1;
  }

  pump.wait ();

  return 0;
}
