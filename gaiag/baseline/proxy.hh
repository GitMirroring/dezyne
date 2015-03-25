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

#ifndef DEZYNE_PROXY_HH
#define DEZYNE_PROXY_HH

#include "IDataparam.hh"


#include "runtime.hh"

namespace dezyne
{
  struct locator;
  struct runtime;

  struct proxy
  {
    dezyne::meta meta;
    runtime& rt;
    IDataparam::Status::type reply_IDataparam_Status;
    IDataparam top;
    IDataparam bottom;

    proxy(const locator&);

    private:
    void top_e0();
    IDataparam::Status::type top_e0r();
    void top_e(int pi);
    IDataparam::Status::type top_er(int pi);
    IDataparam::Status::type top_eer(int i, int j);
    void top_eo(int& i);
    void top_eoo(int& i, int& j);
    void top_eio(int i, int& j);
    void top_eio2(int& i);
    IDataparam::Status::type top_eor(int& i);
    IDataparam::Status::type top_eoor(int& i, int& j);
    IDataparam::Status::type top_eior(int i, int& j);
    IDataparam::Status::type top_eio2r(int& i);
    void bottom_a0();
    void bottom_a(int i);
    void bottom_aa(int i, int j);
    void bottom_a6(int A0, int A1, int A2, int A3, int A4, int A5);
    void outfunc(int& i);
    void deferfunc(int i);
  };
}
#endif // DEZYNE_PROXY_HH
