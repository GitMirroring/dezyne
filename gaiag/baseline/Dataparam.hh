// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DEZYNE_DATAPARAM_HH
#define DEZYNE_DATAPARAM_HH

#include "IDataparam.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct Dataparam
  {
    dezyne::meta meta;
    runtime& rt;
    int mi;
    IDataparam::Status::type s;
    IDataparam::Status::type reply_IDataparam_Status;
    IDataparam port;

    Dataparam(const locator&);

    private:
    void port_e0();
    IDataparam::Status::type port_e0r();
    void port_e(int i);
    IDataparam::Status::type port_er(int i);
    IDataparam::Status::type port_eer(int i, int j);
    void port_eo(int& i);
    void port_eoo(int& i, int& j);
    void port_eio(int i, int& j);
    void port_eio2(int& i);
    IDataparam::Status::type port_eor(int& i);
    IDataparam::Status::type port_eoor(int& i, int& j);
    IDataparam::Status::type port_eior(int i, int& j);
    IDataparam::Status::type port_eio2r(int& i);
    IDataparam::Status::type fun();
    IDataparam::Status::type funx(int xi);
    int xfunx(int xi, int xj);
  };
}
#endif // DEZYNE_DATAPARAM_HH
