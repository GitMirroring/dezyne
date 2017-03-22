// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include <dzn/container.hh>

#include "SimpleBlockingBinding.hh"

void
connect_ports (dzn::container<SimpleBlockingBinding, std::function<void()> >& c)
{
  c.system.r.in.e = [&] () {
    dzn::trace_in(std::clog, c.system.r.meta, "e"); std::clog << std::endl;
    c.match("r.e"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r.meta, tmp.substr(tmp.rfind('.')+1).c_str()); std::clog << std::endl;
    return to__void(tmp.substr(tmp.rfind('.')+1));
  };
}


std::map<std::string, std::function<void()> >
event_map (dzn::container<SimpleBlockingBinding, std::function<void()> >& c)
{
  c.system.p.meta.requires.port = "p";

  c.system.r.meta.provides.address = &c;
  c.system.r.meta.provides.meta = &c.meta;
  c.system.r.meta.provides.port = "r";


  return {
    {"p.e",[&]{int _0 = 0; c.system.p.in.e(_0);
        assert(_0 == 456);
        c.match("p.return");}}
    ,{"r.cb",[&]{c.system.r.out.cb();
      }}
    ,{"r.<flush>",[&]{std::clog << "r.<flush>" << std::endl; c.runtime.flush(&c);}}
  };
}


int
main(int argc, char* argv[])
{
  dzn::container<SimpleBlockingBinding, std::function<void()> > c(argc > 1 && argv[1] == std::string("--flush"));

  connect_ports (c);
  c(event_map (c), {"r"});
}
