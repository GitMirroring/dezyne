#include "SirenComponent.h"

struct SirenForeign: public SirenComponent
                    , public Siren
                    , public boost::enable_shared_from_this<SirenForeign>
{
  void GetAPI(boost::shared_ptr<Siren>* api)
  {
    *api = shared_from_this();
  }
  void turnon()
  {
  }
  void turnoff()
  {
  }
};

boost::shared_ptr<SirenInterface> SirenComponent::GetInstance()
{
  boost::make_shared<SirenForeign>();
}
void SirenComponent::ReleaseInstance()
{
}
