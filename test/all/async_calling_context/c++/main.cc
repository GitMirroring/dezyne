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

#include "async_calling_context.hh"

#include <algorithm>
#include <cstring>

int to_int(std::string s){return std::stoi (s);}
bool to_bool(std::string s){return s == "true";}
void to_void(std::string){}

calling_context dzn_cc;

void
connect_ports (dzn::container< async_calling_context, std::function<void()>>& c)
{
  c.system.p.out.world = [&] (calling_context&, std::string) {
    c.match("p.world");
    return dzn::call_out(&c, [&]{
      if(c.dzn_rt.performs_flush(&c)) c.dzn_rt.queue(&c).push([&]{
        if(c.dzn_rt.queue(&c).empty()) {
          std::clog << "p.<flush>" << std::endl;
          c.match("p.<flush>");
        }
      });}, c.system.p, "world");};}

std::map<std::string,std::function<void()> >
event_map (dzn::container< async_calling_context, std::function<void()>>& c)
{
  c.system.p.meta.require.component = &c;
  c.system.p.meta.require.meta = &c.meta;
  c.system.p.meta.require.name = "p";

  return {{"illegal", []{std::clog << "illegal" << std::endl;}}
    ,{"error", []{std::clog << "sut.error -> sut.error" << std::endl; std::exit(0);}}
    , {"p.hello",[&]{
        std::string s;
        c.match("p.hello");
        c.system.p.in.hello(dzn_cc, s);
        c.match("p.return");
      }}
    , {"p.bye",[&]{
        c.match("p.bye");
        c.system.p.in.bye(dzn_cc);
        c.match("p.return");
      }}
    , {"a.ack",[&]{
       std::string s;
        c.system.a.out.ack(dzn_cc, s);
      }}
  };
}

int
main(int argc, char* argv[])
{
  bool flush = argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--flush") == 0;});
  if(argv + argc != std::find_if(argv + 1, argv + argc, [](const char* s){return std::strcmp(s,"--debug") == 0;})) dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::container< async_calling_context, std::function<void()>> c(flush);

  connect_ports (c);
  c(event_map (c));
}
