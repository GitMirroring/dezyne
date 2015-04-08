// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:


#include "runtime.hh"
#include "locator.hh"

#include "Siren.hh"

#include <iostream>

namespace dezyne
{
  typedef std::map<std::string, std::function<void()>> event_map;

  void fill_event_map(Siren& m, event_map& e)
  {
    int dzn_i = 0;
    if (not m.siren.in.turnon) {
      m.siren.in.turnon = [] () {std::clog << "siren.in.turnon" << std::endl;};
    }
    if (e.find("siren.turnon") == e.end()) e["siren.turnon"] = m.siren.in.turnon; 
    if (not m.siren.in.turnoff) {
      m.siren.in.turnoff = [] () {std::clog << "siren.in.turnoff" << std::endl;};
    }
    if (e.find("siren.turnoff") == e.end()) e["siren.turnoff"] = m.siren.in.turnoff; 
  }
}

int main()
{
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);

  dezyne::event_map event_map;
  dezyne::Siren sut(l);
  sut.dzn_meta.name = "sut";

  dezyne::fill_event_map(sut, event_map); 
  sut.check_bindings();
  sut.dump_tree();

  std::string event;
  while(std::cin >> event) {
    event_map[event]();
  }
}
