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

#include "runtime.h"

bool runtime_handling(void* scope)
{
//  return queues[scope].first;
}

void runtime_flush(void* scope)
{
/*
  std::map<void*, std::pair<bool, std::queue<boost::function<void()> > > >& qs = queues;
  std::map<void*, std::pair<bool, std::queue<boost::function<void()> > > >::iterator it = qs.find(scope);
  if(it != qs.end())
  {
    std::queue<boost::function<void()> >& q = it->second.second;
    while(not q.empty())
    {
      q.front()();
      q.pop();
    }
  }
*/
}

void runtime_defer(void* scope, void *event)
{
//  queues[scope].second.push(event);
}

void runtime_handle_event(void* scope, void* event)
{
/*
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
*/
}
