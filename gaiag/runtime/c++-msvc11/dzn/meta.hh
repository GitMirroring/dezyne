// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include <cassert>
#include <functional>
#include <string>
#include <stdexcept>
#include <vector>

namespace dzn
{
  struct meta;

  namespace port
  {
    struct meta
    {
      struct
      {
        std::string port;
        void* address;
        const dzn::meta* meta;
      } provides;

      struct
      {
        std::string port;
        void* address;
        const dzn::meta* meta;
      } requires;
    };
  }

  struct meta
  {
    std::string name;
    std::string type;
    const meta* parent;
    std::vector<const meta*> children;
    std::vector<std::function<void()>> ports_connected;
    meta(std::string&& name, std::string&& type, const meta* parent, std::vector<const meta*>&& children, std::vector<std::function<void()>>&& ports_connected)
    : name(name)
    , type(type)
    , parent(parent)
    , children(children)
    , ports_connected(ports_connected)
    {}
    meta() {}
  };

  inline std::string path(const meta* m, std::string p = std::string())
  {
    p = p.empty() ? p : "." + p;
    if(!m) return "<external>" + p;
    if(!m->parent) return m->name + p;
    return path(m->parent, m->name + p);
  }

  struct binding_error: public std::runtime_error
  {
    binding_error(const port::meta& m, const std::string& msg)
    : std::runtime_error("not connected: " + path(m.provides.address ? m.provides.meta : m.requires.meta, m.provides.address ? m.provides.port : m.requires.port) + "." + msg)
    {}
  };
}
#endif
