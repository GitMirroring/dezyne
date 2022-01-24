// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

#include "shell_injected.hh"

#include <algorithm>
#include <cstring>

int to_int(std::string s){return std::stoi (s);}
bool to_bool(std::string s){return s == "true";}
void to_void(std::string){}

void
connect_ports (dzn::container< shell_injected, std::function<void()>>& c)
{
  c.system.r.in.e = [&] () {
    dzn::trace(std::clog, c.system.r.meta, "e");
    c.match("r.e");
    std::string tmp = c.match_return();
    dzn::trace_out(std::clog, c.system.r.meta, tmp.substr(tmp.rfind('.')+1).c_str());
    return to_void(tmp.substr(tmp.rfind('.')+1));
  };c.system.p.out.f = [&] () {
    c.match("p.f");
    return dzn::call_out(&c, [&]{
      if(c.flush) c.dzn_rt.queue(&c).push([&]{
        if(c.dzn_rt.queue(&c).empty()) {
          std::clog << "p.<flush>" << std::endl;
          c.match("p.<flush>");
        }
      });}, c.system.p, "f");};}

std::map<std::string,std::function<void()> >
event_map (dzn::container< shell_injected, std::function<void()>>& c)
{
  c.system.p.meta.require.component = &c;
  c.system.p.meta.require.meta = &c.meta;
  c.system.p.meta.require.name = "p";
  c.system.r.meta.provide.component = &c;
  c.system.r.meta.provide.meta = &c.meta;
  c.system.r.meta.provide.name = "r";

  return {{"illegal", []{std::clog << "illegal" << std::endl;}}
    ,{"error", []{std::clog << "sut.error -> sut.error" << std::endl; std::exit(0);}}
    , {"p.e",[&]{
        c.system.p.in.e();
        c.match("p.return");
      }}
    , {"r.f",[&]{
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        c.system.r.out.f();
      }}
    , {"r.<flush>",[&]{
        std::clog << "r.<flush>" << std::endl;
        c.dzn_rt.flush(&c);
      }}};
}

int
main(int argc, char* argv[])
{
  bool flush = argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--flush") == 0;});
  if(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--debug") == 0;})) dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::container< shell_injected, std::function<void()>> c(flush);

  connect_ports (c);
  c(event_map (c), {"r"});
}
