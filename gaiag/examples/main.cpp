#include "AlarmSystemComponent.h"

#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/make_shared.hpp>

#include <iostream>
#include <map>
#include <queue>

namespace asd
{
  using boost::function;
  using boost::bind;
}

std::map<void*, std::pair<bool, std::queue<asd::function<void()> > > >& queues()
{
  static std::map<void*, std::pair<bool, std::queue<asd::function<void()> > > > instance;
  return instance;
}

bool& handling(void* scope)
{
  return queues()[scope].first;
}

void flush(void* scope)
{
  std::map<void*, std::pair<bool, std::queue<asd::function<void()> > > >& qs = queues();
  std::map<void*, std::pair<bool, std::queue<asd::function<void()> > > >::iterator it = qs.find(scope);
  if(it != qs.end())
  {
    std::queue<asd::function<void()> >& q = it->second.second;
    while(not q.empty())
    {
      q.front()();
      q.pop();
    }
  }
}

void defer(void* scope, const asd::function<void()>& event)
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

void handle_event(void* scope, const asd::function<void()>& event)
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

struct CB: public Console_CB
{
  boost::shared_ptr<Console_API> api;
  CB(  boost::shared_ptr<Console_API> api)
  : api(api)
  {}
  void detected()
  {
    std::cout << "Console_CB.detected" << std::endl;
    api->disarm();
  }
  void deactivated()
  {
    std::cout << "Console_CB.deactivated" << std::endl;
  }
};

int main()
{
  boost::shared_ptr<AlarmSystemInterface> alarm_system = AlarmSystemComponent::GetInstance();
  boost::shared_ptr<Console_API> api;
  alarm_system->GetAPI(&api);
  alarm_system->RegisterCB(boost::make_shared<CB>(api));

  api->arm();
}
