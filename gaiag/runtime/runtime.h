// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef RUNTIME_H
#define RUNTIME_H

#include <boost/function.hpp>

#include <map>
#include <queue>

namespace dezyne {

using boost::function;

struct runtime
{
  std::map<void*, std::pair<bool, std::queue<function<void()> > > > queues;

  bool& handling(void*);
  void flush(void*);
  void defer(void*, const function<void()>&);
  void handle_event(void*, const function<void()>&);

  template <typename T>
  struct scoped_value
  {
    T& current;
    T initial;
    scoped_value(T& current, T value)
    : current(current)
    , initial(current)
    { current = value; }
    ~scoped_value()
    {
      current = initial;
    }
  };
};
}
#endif
