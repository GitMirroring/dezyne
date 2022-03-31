// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger van Beusekom <rutger@dezyne.org>
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

#include "blocking_race_async.hh"

#include <dzn/container.hh>

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
main ()
{
  dzn::container<blocking_race_async, std::function<void()>> c(false);
  blocking_race_async& sut = c.system;
  c.meta.name = "c";
  c.meta.parent = 0;

  sut.dzn_meta.parent = &c.meta;
  sut.dzn_meta.name = "sut";
  sut.pt.meta.require.name = "pt";
  sut.pt.meta.require.port = &sut.pt;
  sut.rb.meta.provide.name = "rb";
  sut.rb.meta.provide.port = &sut.rb;
  sut.rt.meta.provide.name = "rt";
  sut.rt.meta.provide.port = &sut.rt;

  bool complete = true;

  sut.pt.out.complete = [&]
  {
    dzn::trace_out(std::clog, sut.pt.meta, "complete");
  };
  sut.rb.in.block = [&]
  {
    dzn::trace(std::clog, sut.rb.meta, "block");
    if(complete) sut.rt.out.complete();
    dzn::trace_out(std::clog, sut.rb.meta, "return");
  };
  sut.rt.in.request = [&]
  {
    dzn::trace(std::clog, sut.rt.meta, "request");
    dzn::trace_out(std::clog, sut.rt.meta, "return");
  };
  sut.rt.in.cancel = [&]
  {
    dzn::trace(std::clog, sut.rt.meta, "cancel");
    dzn::trace_out(std::clog, sut.rt.meta, "return");
  };

  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "pt.cancel\nrt.cancel\nrt.return\npt.return")
  {
    c.pump(sut.pt.in.cancel);
  }
  else if (trace == "pt.request\nrt.request\nrt.return\nrb.block\nrt.complete\nrb.return\nrt.cancel\nrt.return\npt.return\npt.cancel\nrt.cancel\nrt.return\npt.return")
  {
    c.pump([&]{sut.pt.in.request(); sut.pt.in.cancel();});
  }
  else if (trace == "pt.request\nrt.request\nrt.return\nrb.block\nrt.complete\nrb.return\nrt.cancel\nrt.return\npt.return\npt.complete")
  {
    c.pump(sut.pt.in.request);
  }
  else if (trace == "pt.request\nrt.request\nrt.return\nrb.block\nrb.return\nrt.cancel\nrt.return\npt.return\npt.cancel\nrt.cancel\nrt.return\npt.return")
  {
    complete = false;
    c.pump([&]{sut.pt.in.request();
    sut.pt.in.cancel();});
  }
  c.pump.wait();
}
