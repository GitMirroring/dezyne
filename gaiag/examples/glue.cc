// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "AlarmSystemComponent.h"

#include <boost/make_shared.hpp>

#include "runtime.h"

#include <iostream>
#include <map>
#include <queue>

std::map<void*, std::pair<bool, std::queue<dezyne::function<void()> > > >& queues()
{
  static std::map<void*, std::pair<bool, std::queue<dezyne::function<void()> > > > instance;
  return instance;
}

bool& handling(void* scope)
{
  return queues()[scope].first;
}

void flush(void* scope)
{
  std::map<void*, std::pair<bool, std::queue<dezyne::function<void()> > > >& qs = queues();
  std::map<void*, std::pair<bool, std::queue<dezyne::function<void()> > > >::iterator it = qs.find(scope);
  if(it != qs.end())
  {
    std::queue<dezyne::function<void()> >& q = it->second.second;
    while(not q.empty())
    {
      q.front()();
      q.pop();
    }
  }
}

void defer(void* scope, const dezyne::function<void()>& event)
{
  queues()[scope].second.push(event);
}

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

void handle_event(void* scope, const dezyne::function<void()>& event)
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

struct CB: public dezyne::IConsoleCB
{
  boost::shared_ptr<dezyne::IConsole> api;
  CB(  boost::shared_ptr<dezyne::IConsole> api)
  : api(api)
  {}
  void Tripped()
  {
    std::cout << "ConsoleCB.Tripped" << std::endl;
  }
  void Deactivated()
  {
    std::cout << "ConsoleCB.Deactivated" << std::endl;
  }
};

int main()
{
  boost::shared_ptr<dezyne::IConsoleInterface> alarm_system = dezyne::AlarmSystemComponent::GetInstance();
  boost::shared_ptr<dezyne::IConsole> api;
  alarm_system->GetAPI(&api);
  alarm_system->RegisterCB(boost::make_shared<CB>(api));

  api->SwitchOn();
  api->SwitchOff();
}
