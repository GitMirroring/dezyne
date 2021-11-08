// Dezyne --- Dezyne command line tools
//
// Copyright © 2018, 2019, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2019 Rutger van Beusekom <rutger@dezyne.org>
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

#include "blocking_binding.hh"

int to_int(std::string s){return std::stoi (s);}
bool to_bool(std::string s){return s == "true";}
void to_void(std::string){}

void
connect_ports (dzn::container<blocking_binding, std::function<void()> >& c)
{
  c.system.w.in.hello = [&] () {
    dzn::trace(std::clog, c.system.w.meta, "hello");
    c.match("w.hello"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.w.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_void(tmp.substr(tmp.rfind('.')+1));
  };
}


std::map<std::string, std::function<void()> >
event_map (dzn::container<blocking_binding, std::function<void()> >& c)
{
  c.system.h.meta.require.port = "h";

  c.system.w.meta.provide.address = &c;
  c.system.w.meta.provide.meta = &c.meta;
  c.system.w.meta.provide.port = "w";


  return {
    {"h.hello",[&]{int _0 = 0; c.system.h.in.hello(_0);
        assert(_0 == 456);
        c.match("h.return");}}
    ,{"w.world",[&]{c.system.w.out.world();
      }}
    ,{"w.<flush>",[&]{std::clog << "w.<flush>" << std::endl; c.dzn_rt.flush(&c);}}
  };
}


int
main(int argc, char* argv[])
{
  dzn::container<blocking_binding, std::function<void()> > c(argc > 1 && argv[1] == std::string("--flush"));

  connect_ports (c);
  c(event_map (c), {"w"});
}
