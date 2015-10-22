// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef INORM2B_HH
#define INORM2B_HH

#include "meta.hh"

#include <cassert>
#include <map>


#ifndef ENUM__Bool
#define ENUM__Bool 1
struct Bool
{
  enum type
  {
    f, t
  };
};
#endif // ENUM__Bool


struct inorm2b
{

  struct
  {
    std::function<Bool::type (int& s)> b;
    std::function<void (int s)> success;
    std::function<void (int status)> fail;
  } in;

  struct
  {
    std::function<void ()> a;
  } out;

  dezyne::port::meta meta;
  inline inorm2b(dezyne::port::meta m) : meta(m) {}

  void check_bindings() const
  {
    if (! in.b) throw dezyne::binding_error_in(meta, "in.b");
    if (! in.success) throw dezyne::binding_error_in(meta, "in.success");
    if (! in.fail) throw dezyne::binding_error_in(meta, "in.fail");

    if (! out.a) throw dezyne::binding_error_out(meta, "out.a");

  }
};

inline void connect (inorm2b& provided, inorm2b& required)
{
  provided.out = required.out;
  required.in = provided.in;
  provided.meta.requires = required.meta.requires;
  required.meta.provides = provided.meta.provides;
}

#ifndef ENUM_TO_STRING__Bool
#define ENUM_TO_STRING__Bool 1
inline const char* to_string(::Bool::type v)
{
  switch(v)
  {
    case ::Bool::f: return "Bool_f";
    case ::Bool::t: return "Bool_t";

  }
  return "";
}
#endif // ENUM_TO_STRING__Bool


#ifndef STRING_TO_ENUM__Bool
#define STRING_TO_ENUM__Bool 1
inline ::Bool::type to__Bool(std::string s)
{
  static std::map<std::string, ::Bool::type> m = {
    {"Bool_f",::Bool::f},
    {"Bool_t",::Bool::t},
  };
  if (m.find(s) != m.end())
  {
    return m[s];
  }
  return (::Bool::type)-1;
}
#endif // STRING_TO_ENUM__Bool


#endif // INORM2B_HH
