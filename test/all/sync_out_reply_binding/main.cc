// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

#include "sync_out_reply_binding.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
//#include <dzn/pump.hh>

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
  sync_out_reply_binding sut (locator);

  sut.dzn_meta.name = "sut";

  sut.h.meta.require.name = "h";
  sut.h.meta.require.port = &sut.h;

  sut.w.meta.provide.name = "w";
  sut.w.meta.provide.port = &sut.w;

  sut.w.in.hello = [&]
  {
    dzn::trace (std::clog, sut.w.meta, "hello");
    sut.w.out.world ();
    dzn::trace_out (std::clog, sut.w.meta, "return");
  };

  sut.w.in.hello_void = [&]
  {
    dzn::trace (std::clog, sut.w.meta, "hello_void");
    sut.w.out.world_void ();
    dzn::trace_out (std::clog, sut.w.meta, "return");
  };

  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "h.hello\nw.hello\nw.world\nw.return\nh.true")
  {
    int v = 0;
    sut.h.in.hello (v);
    assert (v == 456);
  }
  else if (trace == "h.hello_void\nw.hello_void\nw.world_void\nw.return\nh.return")
  {
    int v = 0;
    sut.h.in.hello_void (v);
    assert (v == 456);
  }
  else
  {
    std::clog << "missing trace" << std::endl;
    return 1;
  }

  return 0;
}
