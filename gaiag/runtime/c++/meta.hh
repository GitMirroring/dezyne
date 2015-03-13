// Dezyne --- Dezyne command line tools
//
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

#ifndef META_HH
#define META_HH

#include <functional>
#include <string>
#include <stdexcept>
#include <vector>

namespace dezyne
{
  namespace port
  {
    struct meta
    {
      struct
      {
        std::string port;
        void*       address;
      } provides;

      struct
      {
        std::string port;
        void*       address;
      } requires;
    };
  }

  struct component;

  struct meta
  {
    std::string name;
    std::string type;
    const component* address;
    const component* parent;
    std::vector<const component*> children;
    std::vector<std::function<void()>> ports_connected;
  };

  struct component
  {
    dezyne::meta meta;
  };

  inline std::string path(meta const& m, std::string p="")
  {
    if(m.parent)
      return path(m.parent->meta, m.name + (p.empty() ? p : "." + p));
    return m.name + (p.empty() ? p : "." + p);
  }

  inline std::string path(void* c, std::string p="")
  {
    if (!c)
      return "0x0." + p;
    return path(reinterpret_cast<const component*>(c)->meta, p);
  }

  struct binding_error_in: public std::runtime_error
  {
    template <typename T>
    binding_error_in(T const& m, const std::string& msg)
    : std::runtime_error("not connected: " + path(m.provides.address ? m.provides.address : m.requires.address, m.provides.address ? m.provides.port : m.requires.port) + "." + msg)
    {}
  };
  struct binding_error_out: public std::runtime_error
  {
    template <typename T>
    binding_error_out(T const& m, const std::string& msg)
    : std::runtime_error("not connected: " + path(m.requires.address ? m.requires.address : m.provides.address, m.requires.address ? m.requires.port : m.provides.port) + "." + msg)
    {}
  };
}
#endif
