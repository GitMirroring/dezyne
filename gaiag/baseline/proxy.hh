// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef COMPONENT_PROXY_HH
#define COMPONENT_PROXY_HH

#include "IDataparam.hh"
#include "IDataparam.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct proxy
  {
    dezyne::runtime& rt;
    interface::IDataparam::Status::type reply_IDataparam_Status;
    interface::IDataparam top;
    interface::IDataparam bottom;

    proxy(const dezyne::locator&);
    void top_e0();
    interface::IDataparam::Status::type top_e0r();
    void top_e(int i);
    interface::IDataparam::Status::type top_er(int i);
    interface::IDataparam::Status::type top_eer(int i, int j);
    void top_eo(int& i);
    void top_eoo(int& i, int& j);
    void top_eio(int i, int& j);
    void top_eio2(int& i);
    interface::IDataparam::Status::type top_eor(int& i);
    interface::IDataparam::Status::type top_eoor(int& i, int& j);
    interface::IDataparam::Status::type top_eior(int i, int& j);
    interface::IDataparam::Status::type top_eio2r(int& i);
    void bottom_a0();
    void bottom_a(int i);
    void bottom_aa(int i, int j);
    void bottom_a6(int a0, int a1, int a2, int a3, int a4, int a5);
  };
}
#endif
