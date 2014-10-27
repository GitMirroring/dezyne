// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "runtime.h"

namespace dezyne {
runtime::runtime(){}

bool& runtime::handling(void* scope)
{
  return queues[scope].first;
}

void runtime::flush(void* scope)
{
  std::map<void*, std::pair<bool, std::queue<function<void()> > > >& qs = queues;
  std::map<void*, std::pair<bool, std::queue<function<void()> > > >::iterator it = qs.find(scope);
  if(it != qs.end())
  {
    std::queue<function<void()> >& q = it->second.second;
    while(not q.empty())
    {
      q.front()();
      q.pop();
    }
  }
}

void runtime::defer(void* scope, const function<void()>& event)
{
  queues[scope].second.push(event);
}

void runtime::handle_event(void* scope, const function<void()>& event)
{
  bool& handle = handling(scope);
  if(not handle)
  {
    scoped_value<bool> sv(handle, true);
    event();
    flush(scope);
  }
  else
  {
    defer(scope, event);
  }
}
}
