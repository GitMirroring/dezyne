// Dezyne --- Dezyne command line tools
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

#ifndef LOCATOR_H
#define LOCATOR_H

#include <map>
#include <stdexcept>
#include <string>
#include <typeinfo>

namespace dezyne {
class locator
{
  typedef std::string Key;
  struct type_info
  {
    const std::type_info* t;
    type_info(const std::type_info& t)
    : t(&t)
    {}
    bool operator < (const type_info& that) const
    {
      return t->before(*that.t);
    }
  };
  std::map<std::pair<Key,type_info>, void*> services;
public:
  locator clone() const
  {
    return locator(*this);
  }
  template <typename T>
  locator& set(T& t, const Key& key = Key())
  {
    services.insert(std::make_pair(std::make_pair(key,type_info(typeid(T))), &t));
    return *this;
  }
  template <typename T>
  T& get(const Key& key = Key()) const
  {
    std::map<std::pair<Key,type_info>, void*>::const_iterator it = services.find(std::make_pair(key,type_info(typeid(T))));
    if(it == services.end() || not it->second) throw std::runtime_error("<" + std::string(typeid(T).name()) + ",\"" + key + "\"> not available");
    return *reinterpret_cast<T*>(it->second);
  }
};
}
#endif
