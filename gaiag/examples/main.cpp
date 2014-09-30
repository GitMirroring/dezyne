#include "AlarmSystemComponent.h"

#include <boost/make_shared.hpp>

#include <iostream>

struct CB: public Console_CB
{
  void detected()
  {
    std::cout << "Console_CB::detected" << std::endl;
  }
  void deactivated()
  {
    std::cout << "Console_CB::deactivated" << std::endl;
  }
};

int main()
{
  boost::shared_ptr<AlarmSystemInterface> alarm_system = AlarmSystemComponent::GetInstance();
  boost::shared_ptr<Console_API> api;
  alarm_system->GetAPI(&api);
  alarm_system->RegisterCB(boost::make_shared<CB>());

  api->arm();
  api->disarm();
}
