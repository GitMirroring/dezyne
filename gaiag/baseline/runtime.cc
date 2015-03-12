// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "runtime.hh"

#include <algorithm>
#include <iostream>

namespace dezyne {

runtime::runtime(){}

void trace_in(port::meta const& m, const char* e)
{
  std::clog << path(m.requires.address, m.requires.port) << "." << e << " -> "
            << path(m.provides.address, m.provides.port) << "." << e << std::endl;
}

void trace_out(port::meta const& m, const char* e)
{
  std::clog << path(m.provides.address, m.provides.port) << "." << e << " -> "
            << path(m.requires.address, m.requires.port) << "." << e << std::endl;
}

bool& runtime::handling(void* scope)
{
  return queues[scope].first;
}

void runtime::flush(void* scope)
{
#ifdef DEBUG
  std::cout << path(scope) << " flush" << std::endl;
#endif
  std::map<void*, std::pair<bool, std::queue<std::function<void()> > > >& qs = queues;
  std::map<void*, std::pair<bool, std::queue<std::function<void()> > > >::iterator it = qs.find(scope);
  if(it != qs.end())
  {
    std::queue<std::function<void()> >& q = it->second.second;
    while(not q.empty())
    {
      std::function<void()> event = q.front();
      q.pop();
      event();
    }
  }
}

void runtime::defer(void* scope, const std::function<void()>& event)
{
  auto it = std::find_if(queues.begin(), queues.end(), [](const std::pair<void*, std::pair<bool, std::queue<std::function<void()>>>>& p){ return p.second.first;});

#ifdef DEBUG
  std::cout << path(scope) << " defer " << std::boolalpha << (it != queues.end()) << std::endl;
#endif

  if(it == queues.end())
  {
    event();
  }
  else
  {
    queues[scope].second.push(event);
  }
}

void runtime::handle(void* scope, const std::function<void()>& event)
{
  bool& handle = handling(scope);

#ifdef DEBUG
  std::cout << path(scope) << " handle " << std::boolalpha << handle << std::endl;
#endif

  if(not handle)
  {
    {
      scoped_value<bool> sv(handle, true);
      event();
    }
    flush(scope);
  }
  else
  {
    defer(scope, [=]{this->handle (scope, event);});
  }
}
}
