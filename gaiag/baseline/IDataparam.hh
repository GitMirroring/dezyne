// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include <cassert>
#include <functional>

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

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } in;

    struct
    {
      std::function<void ()> a0;
      std::function<void (int i)> a;
      std::function<void (int i, int j)> aa;
      std::function<void (int a0, int a1, int a2, int a3, int a4, int a5)> a6;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } out;
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
