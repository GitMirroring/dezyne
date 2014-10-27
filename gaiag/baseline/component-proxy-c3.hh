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

#ifndef COMPONENT_PROXY_HH
#define COMPONENT_PROXY_HH

#include "interface-idataparam-c3.hh"
#include "interface-idataparam-c3.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct proxy
  {
    dezyne::runtime& rt;
    interface::idataparam::Status::type reply_idataparam_Status;
    interface::idataparam top;
    interface::idataparam bottom;

    proxy(const dezyne::locator&);
    void top_e0();
    interface::idataparam::Status::type top_e0r();
    void top_e(int i);
    interface::idataparam::Status::type top_er(int i);
    interface::idataparam::Status::type top_eer(int i, int j);
    void top_eo(int& i);
    void top_eoo(int& i, int& j);
    void top_eio(int i, int& j);
    void top_eio2(int& i);
    interface::idataparam::Status::type top_eor(int& i);
    interface::idataparam::Status::type top_eoor(int& i, int& j);
    interface::idataparam::Status::type top_eior(int i, int& j);
    interface::idataparam::Status::type top_eio2r(int& i);
    void bottom_a0();
    void bottom_a(int i);
    void bottom_aa(int i, int j);
    void bottom_a6(int a0, int a1, int a2, int a3, int a4, int a5);
  };
}
#endif
