// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#ifndef DEZYNE_IDATAPARAM_HH
#define DEZYNE_IDATAPARAM_HH

#include "meta.hh"

#include <cassert>

namespace dezyne
{
  struct IDataparam
  {
    struct Status
    {
      enum type
      {
        Yes, No
      };
    };

    struct
    {
      std::function<void ()> e0;
      std::function<Status::type ()> e0r;
      std::function<void (int i)> e;
      std::function<Status::type (int i)> er;
      std::function<Status::type (int i, int j)> eer;
      std::function<void (int& i)> eo;
      std::function<void (int& i, int& j)> eoo;
      std::function<void (int i, int& j)> eio;
      std::function<void (int& i)> eio2;
      std::function<Status::type (int& i)> eor;
      std::function<Status::type (int& i, int& j)> eoor;
      std::function<Status::type (int i, int& j)> eior;
      std::function<Status::type (int& i)> eio2r;
    } in;

    struct
    {
      std::function<void ()> a0;
      std::function<void (int i)> a;
      std::function<void (int i, int j)> aa;
      std::function<void (int a0, int a1, int a2, int a3, int a4, int a5)> a6;
    } out;

    port::meta meta;
    inline IDataparam(port::meta m) : meta(m) {}

    void check_bindings() const
    {
      if (not in.e0) throw dezyne::binding_error_in(meta, "in.e0");
      if (not in.e0r) throw dezyne::binding_error_in(meta, "in.e0r");
      if (not in.e) throw dezyne::binding_error_in(meta, "in.e");
      if (not in.er) throw dezyne::binding_error_in(meta, "in.er");
      if (not in.eer) throw dezyne::binding_error_in(meta, "in.eer");
      if (not in.eo) throw dezyne::binding_error_in(meta, "in.eo");
      if (not in.eoo) throw dezyne::binding_error_in(meta, "in.eoo");
      if (not in.eio) throw dezyne::binding_error_in(meta, "in.eio");
      if (not in.eio2) throw dezyne::binding_error_in(meta, "in.eio2");
      if (not in.eor) throw dezyne::binding_error_in(meta, "in.eor");
      if (not in.eoor) throw dezyne::binding_error_in(meta, "in.eoor");
      if (not in.eior) throw dezyne::binding_error_in(meta, "in.eior");
      if (not in.eio2r) throw dezyne::binding_error_in(meta, "in.eio2r");

      if (not out.a0) throw dezyne::binding_error_out(meta, "out.a0");
      if (not out.a) throw dezyne::binding_error_out(meta, "out.a");
      if (not out.aa) throw dezyne::binding_error_out(meta, "out.aa");
      if (not out.a6) throw dezyne::binding_error_out(meta, "out.a6");

    }
  };

  inline void connect (IDataparam& provided, IDataparam& required)
  {
    assert (not required.in.e0);
    assert (not required.in.e0r);
    assert (not required.in.e);
    assert (not required.in.er);
    assert (not required.in.eer);
    assert (not required.in.eo);
    assert (not required.in.eoo);
    assert (not required.in.eio);
    assert (not required.in.eio2);
    assert (not required.in.eor);
    assert (not required.in.eoor);
    assert (not required.in.eior);
    assert (not required.in.eio2r);

    assert (not provided.out.a0);
    assert (not provided.out.a);
    assert (not provided.out.aa);
    assert (not provided.out.a6);

    provided.out = required.out;
    required.in = provided.in;
    provided.meta.requires = required.meta.requires;
    required.meta.provides = provided.meta.provides;
  }
  inline const char* to_string(IDataparam::Status::type v)
  {
    switch(v)
    {
      case IDataparam::Status::Yes: return "Status_Yes";
      case IDataparam::Status::No: return "Status_No";

    }
    return "";
  }

}
#endif // DEZYNE_IDATAPARAM_HH
