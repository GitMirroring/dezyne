#include "SirenExtComponent.h"

#include <boost/enable_shared_from_this.hpp>
#include <boost/make_shared.hpp>

#include <iostream>

struct SirenForeign: public SirenExtComponent
                   , public Siren
                   , public boost::enable_shared_from_this<SirenForeign>
{
  void GetAPI(boost::shared_ptr<Siren>* api)
  {
    *api = shared_from_this();
  }
  void Turnon()
  {
    std::cout << "Siren.Turnon" << std::endl;
  }
  void Turnoff()
  {
    std::cout << "Siren.Turnoff" << std::endl;
  }
};

boost::shared_ptr<SirenInterface> SirenExtComponent::GetInstance()
{
  return boost::make_shared<SirenForeign>();
}
void SirenExtComponent::ReleaseInstance()
{
}
