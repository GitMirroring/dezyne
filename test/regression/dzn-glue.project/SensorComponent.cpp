#include "SensorComponent.h"

#include <boost/enable_shared_from_this.hpp>
#include <boost/make_shared.hpp>

#include <iostream>

struct SensorForeign: public SensorComponent
                    , public ISensor
                    , public boost::enable_shared_from_this<SensorForeign>
{
  boost::shared_ptr<ISensorCB> cb;
  boost::shared_ptr<asd::channels::ISingleThreaded> st;

  void GetAPI(boost::shared_ptr<ISensor>* api)
  {
    *api = shared_from_this();
  }
  void RegisterCB(boost::shared_ptr<ISensorCB> cb)
  {
    this->cb = cb;
  }
  void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> st)
  {
    this->st = st;
  }

  void Enable()
  {
    std::cout << "Sensor.Enable" << std::endl;
    std::cout << "Sensor.Triggered" << std::endl;
    cb->Triggered();
    st->processCBs();
  }
  void Disable()
  {
    std::cout << "Sensor.Disable" << std::endl;
    std::cout << "Sensor.Disabled" << std::endl;
    cb->Disabled();
    st->processCBs();
  }
};

boost::shared_ptr<ISensorInterface> SensorComponent::GetInstance()
{
  return boost::make_shared<SensorForeign>();
}
void SensorComponent::ReleaseInstance()
{
}
