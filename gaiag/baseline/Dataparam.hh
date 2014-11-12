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

#ifndef COMPONENT_DATAPARAM_HH
#define COMPONENT_DATAPARAM_HH

#include "IDataparam.hh"


namespace dezyne {
  struct locator;
  struct runtime;
}

namespace component
{
  struct Dataparam
  {
    dezyne::runtime& rt;
    int mi;
    interface::IDataparam::Status::type s;
    interface::IDataparam::Status::type reply_IDataparam_Status;
    interface::IDataparam port;

    Dataparam(const dezyne::locator&);
    void port_e0();
    interface::IDataparam::Status::type port_e0r();
    void port_e(int i);
    interface::IDataparam::Status::type port_er(int i);
    interface::IDataparam::Status::type port_eer(int i, int j);
    void port_eo(int& i);
    void port_eoo(int& i, int& j);
    void port_eio(int i, int& j);
    void port_eio2(int& i);
    interface::IDataparam::Status::type port_eor(int& i);
    interface::IDataparam::Status::type port_eoor(int& i, int& j);
    interface::IDataparam::Status::type port_eior(int i, int& j);
    interface::IDataparam::Status::type port_eio2r(int& i);
    interface::IDataparam::Status::type fun();
    interface::IDataparam::Status::type funx(int xi);
    int xfunx(int xi, int xj);
  };
}
#endif
