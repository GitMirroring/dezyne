// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <dzn/container.hh>

#include "blocking_shell.hh"

#include <algorithm>
#include <cstring>
#include <thread>

int to_int(std::string s){return std::stoi (s);}
bool to_bool(std::string s){return s == "true";}
void to_void(std::string){}

void
connect_ports (dzn::container< blocking_shell, std::function<void()>>& c)
{
  c.system.r.in.hello_void = [&] () {
    dzn::trace(std::clog, c.system.r.meta, "hello_void");
    c.match("r.hello_void");
    std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_void(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.r.in.hello_int = [&] () {
    dzn::trace(std::clog, c.system.r.meta, "hello_int");
    c.match("r.hello_int");
    std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_int(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.r.in.hello_bool = [&] () {
    dzn::trace(std::clog, c.system.r.meta, "hello_bool");
    c.match("r.hello_bool");
    std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_bool(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.r.in.hello_enum = [&] (int i,int& j) {
    dzn::trace(std::clog, c.system.r.meta, "hello_enum");
    c.match("r.hello_enum");
    std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_Enum(tmp.substr(tmp.rfind('.')+1));
  };
  c.system.p.out.world = [&] (int) {
    c.match("p.world");
    return dzn::call_out(&c, [&]{
      if(c.flush) c.dzn_rt.queue(&c).push([&]{
        if(c.dzn_rt.queue(&c).empty()) {
          std::clog << "p.<flush>" << std::endl;
          c.match("p.<flush>");
        }
      });}, c.system.p, "world");};}

std::map<std::string,std::function<void()> >
event_map (dzn::container< blocking_shell, std::function<void()>>& c)
{
  c.system.p.meta.require.component = &c;
  c.system.p.meta.require.meta = &c.meta;
  c.system.p.meta.require.name = "p";
  c.system.r.meta.provide.component = &c;
  c.system.r.meta.provide.meta = &c.meta;
  c.system.r.meta.provide.name = "r";

  return {{"illegal", []{std::clog << "illegal" << std::endl;}}
    ,{"error", []{std::clog << "sut.error -> sut.error" << std::endl; std::exit(0);}}
    , {"p.hello_void",[&]{c.system.p.in.hello_void(); c.match("p.return");}}
    , {"r.world",[&]{std::this_thread::sleep_for(std::chrono::milliseconds(1000)); int _0 = 0; c.system.r.out.world(0);}}
    , {"p.hello_int",[&]{c.match("p." + to_string(c.system.p.in.hello_int())); std::queue<std::function<void()>> empty; std::swap(c.dzn_rt.queue(&c.system.p), empty);}}
    , {"p.hello_bool",[&]{c.match("p." + to_string(c.system.p.in.hello_bool())); std::queue<std::function<void()>> empty; std::swap(c.dzn_rt.queue(&c.system.p), empty);}}
    , {"p.hello_enum",[&]{int _0 = 0; int _1 = 1;c.match("p." + to_string(c.system.p.in.hello_enum(0,_1))); std::queue<std::function<void()>> empty; std::swap(c.dzn_rt.queue(&c.system.p), empty);}}
    , {"r.<flush>",[&]{std::clog << "r.<flush>" << std::endl; c.dzn_rt.flush(&c);}}
  };
}

int
main(int argc, char* argv[])
{
  bool flush = argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--flush") == 0;});
  if(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--debug") == 0;})) dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::container< blocking_shell, std::function<void()>> c(flush);

  connect_ports (c);
  c(event_map (c), {"r"});
}
