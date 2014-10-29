// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Gaiag.
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

#ifndef COMPONENT_DATAPARAM_HH
#define COMPONENT_DATAPARAM_HH

#include "interface-idataparam-c3.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct dataparam
  {
    dezyne::runtime& rt;
    int mi;
    interface::idataparam::Status::type s;
    interface::idataparam::Status::type reply_idataparam_Status;
    interface::idataparam port;

    dataparam(const dezyne::locator&);
    void port_e0();
    interface::idataparam::Status::type port_e0r();
    void port_e(int i);
    interface::idataparam::Status::type port_er(int i);
    interface::idataparam::Status::type port_eer(int i, int j);
    void port_eo(int& i);
    void port_eoo(int& i, int& j);
    void port_eio(int i, int& j);
    void port_eio2(int& i);
    interface::idataparam::Status::type port_eor(int& i);
    interface::idataparam::Status::type port_eoor(int& i, int& j);
    interface::idataparam::Status::type port_eior(int i, int& j);
    interface::idataparam::Status::type port_eio2r(int& i);
    interface::idataparam::Status::type fun();
    interface::idataparam::Status::type funx(int xi);
    int xfunx(int xi, int xj);
  };
}
#endif
