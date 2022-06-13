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

#include "async_shell.hh"

#include <algorithm>
#include <cstring>

int to_int(std::string s){return std::stoi (s);}
bool to_bool(std::string s){return s == "true";}
void to_void(std::string){}

void
connect_ports (dzn::container< async_shell, std::function<void()>>& c)
{
  c.system.h.out.world = [&] () {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    c.match("h.world");
    return dzn::call_out(&c, [&]{
      if(c.flush) c.dzn_rt.queue(&c).push([&]{
        if(c.dzn_rt.queue(&c).empty()) {
          std::clog << "h.<flush>" << std::endl;
          c.match("h.<flush>");
        }
      });}, c.system.h, "world");};}

std::map<std::string,std::function<void()> >
event_map (dzn::container< async_shell, std::function<void()>>& c)
{
  c.system.h.meta.require.component = &c;
  c.system.h.meta.require.meta = &c.meta;
  c.system.h.meta.require.name = "h";

  return {{"illegal", []{std::clog << "illegal" << std::endl;}}
    ,{"error", []{std::clog << "sut.error -> sut.error" << std::endl; std::exit(0);}}
    , {"h.hello",[&]{
        c.match("h.hello");
        c.system.h.in.hello();
        c.match("h.return");
      }}
  };
}

int
main(int argc, char* argv[])
{
  bool flush = argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--flush") == 0;});
  if(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--debug") == 0;})) dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::container< async_shell, std::function<void()>> c(flush);

  connect_ports (c);
  c(event_map (c));
}
