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

#include <boost/bind.hpp>
#include <boost/bind/protect.hpp>
#include <boost/function.hpp>

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
      meta()
      : provides()
      , requires()
      {}
      struct detail
      {
        detail()
        : port()
        , address()
        , meta()
        {}
        std::string port;
        void* address;
        const dzn::meta* meta;
      };
      detail provides;
      detail requires;
    };
  }

  struct meta
  {
    meta(const std::string& name, const std::string& type, const meta* parent)
    : name(name)
    , type(type)
    , parent(parent)
    {}
    meta () {}
    std::string name;
    std::string type;
    const meta* parent;
    std::vector<const meta*> children;
    std::vector<boost::function<void()> > ports_connected;
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
