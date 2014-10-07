// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "component-Siren-c3.hh"

void handle_event(void*, const asd::function<void()>&);

template <typename R>
inline asd::function<R()> connect(void*, const asd::function<R()>& event)
{
  return event;
}

template <>
inline asd::function<void()> connect<void>(void* scope, const asd::function<void()>& event)
{
  return asd::bind(handle_event, scope, event);
}

namespace component
{
  Siren::Siren()
  : po_siren()
  {
    po_siren.in.turnon = connect<void>(this, asd::bind<void>(&Siren::po_siren_turnon, this));
    po_siren.in.turnoff = connect<void>(this, asd::bind<void>(&Siren::po_siren_turnoff, this));
  }

  void Siren::po_siren_turnon()
  {
    std::cout << "Siren.po_siren_turnon" << std::endl;


  }
  void Siren::po_siren_turnoff()
  {
    std::cout << "Siren.po_siren_turnoff" << std::endl;


  }



}
