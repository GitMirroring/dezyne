// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


// handwritten generic main
#include "runtime.hh"
#include "locator.hh"

#define STR(s) #s
#define XSTR(s) STR(s)
#define HEADER(NAME) NAME.hh
#define COMPONENT_HH XSTR(HEADER(COMPONENT))

#include COMPONENT_HH

#include <iostream>

int main()
{
  dezyne::runtime rt;
  dezyne::locator l;
  l.set(rt);

  std::map<std::string, std::function<void()>> event_map;
  l.set(event_map, "event-map");

  dezyne::COMPONENT sut(l);

  sut.dzn_meta.name = "sut";

  std::string event;
  while(std::cin >> event)
  {
    event_map[event]();
  }
}
