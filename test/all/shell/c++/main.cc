// Dezyne --- Dezyne command line tools
//
// Copyright © 2017, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

//FIXME: workaround multi-threaded race condition
//dedicated container.hh with std::this_thread::sleep_for
#include "container.hh"

#include "shell.hh"

#include <algorithm>
#include <cassert>
#include <cstring>

int to_int(std::string s){return std::stoi (s);}
bool to_bool(std::string s){return s == "true";}
void to_void(std::string){}

void
connect_ports (dzn::container< ::shell, std::function<void()>>& c)
{
  c.system.r_outer.in.return_void = [&] () {
    dzn::trace(std::clog, c.system.r_outer.meta, "return_void");
    c.match("r_outer.return_void"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r_outer.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_void(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.r_outer.in.return_int = [&] () {
    dzn::trace(std::clog, c.system.r_outer.meta, "return_int");
    c.match("r_outer.return_int"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r_outer.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_int(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.r_outer.in.return_bool = [&] () {
    dzn::trace(std::clog, c.system.r_outer.meta, "return_bool");
    c.match("r_outer.return_bool"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r_outer.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_bool(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.r_outer.in.return_enum = [&] (int i,int& j) {
    j = i;
    dzn::trace(std::clog, c.system.r_outer.meta, "return_enum");
    c.match("r_outer.return_enum"); std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r_outer.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_Enum(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.p_outer.out.foo = [&] (int i) {
    dzn::trace_out(std::clog, c.system.p_outer.meta, "foo");
    c.match("p_outer.foo");
  };
}

std::map<std::string,std::function<void()> >
event_map (dzn::container< ::shell, std::function<void()>>& c)
{
  c.system.p_outer.meta.require.port = "p_outer";

  c.system.r_outer.meta.provide.address = &c;
  c.system.r_outer.meta.provide.meta = &c.meta;
  c.system.r_outer.meta.provide.port = "r_outer";


  return {{"illegal", []{std::clog << "illegal" << std::endl; std::exit(0);}}
    , {"r_outer.foo",[&]{c.system.r_outer.out.foo(0);}}
    , {"p_outer.return_void",[&]{std::thread([&]{c.system.p_outer.in.return_void(); c.match("p_outer.return");}).detach();}}
    , {"p_outer.return_int",[&]{std::thread([&]{c.match("p_outer." + to_string(c.system.p_outer.in.return_int()));}).detach();}}
    , {"p_outer.return_bool",[&]{std::thread([&]{c.match("p_outer." + to_string(c.system.p_outer.in.return_bool()));}).detach();}}
    , {"p_outer.return_enum",[&]{std::thread([&]{int _1 = 1; c.match("p_outer." + to_string(c.system.p_outer.in.return_enum(0,_1))); assert(_1 == 0);}).detach();}}
    , {"r_outer.<flush>",[&]{std::clog << "r_outer.<flush>" << std::endl; c.dzn_rt.flush(&c);}}
  };
}

int
main(int argc, char* argv[])
{
  if(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--debug") == 0;})) dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::container< ::shell, std::function<void()>> c(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--flush") == 0;}));

  connect_ports (c);
  c(event_map (c), {"r_outer"});
}
