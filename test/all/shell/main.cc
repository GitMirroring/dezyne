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

#include "shell.hh"

void
connect_ports (dzn::container<shell>& c)
{
  c.system.p_outer.out.foo = [&] (int i) {
    dzn::trace_out(std::clog, c.system.p_outer.meta, "foo"); std::clog << std::endl;
    c.match("p_outer.foo");
  };
  c.system.r_outer.in.return_to_sender = [&] (int i, int& j) {
    dzn::trace_in(std::clog, c.system.r_outer.meta, "return_to_sender"); std::clog << std::endl;
    c.match("r_outer.return_to_sender"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r_outer.meta, tmp.substr(tmp.rfind('.')+1).c_str()); std::clog << std::endl;
    return to__bool(tmp.substr(tmp.rfind('.')+1));
  };
}


std::map<std::string,std::function<void()> >
event_map (dzn::container<shell>& c)
{
  c.system.p_outer.meta.requires.port = "p_outer";

  c.system.r_outer.meta.provides.address = &c;
  c.system.r_outer.meta.provides.meta = &c.meta;
  c.system.r_outer.meta.provides.port = "r_outer";


  return {
    {"illegal",                  []{std::clog << "illegal" << std::endl; std::exit(0);}},
    {"p_outer.return_to_sender", [&]{std::thread([&]{int _1 = 1; c.match("p_outer." + to_string(c.system.p_outer.in.return_to_sender(int(0),_1))); }).detach();}},
    {"r_outer.foo",              [&]{c.system.r_outer.out.foo(int(0));}},
    {"r_outer.<flush>",          [&]{std::clog << "r_outer.<flush>" << std::endl; c.runtime.flush(&c);}}
  };
}


int
main(int argc, char* argv[])
{
  dzn::container<shell> c(argc > 1 && argv[1] == std::string("--flush"));
  connect_ports (c);
  c(event_map (c), {"r_outer"});
}
