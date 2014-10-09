#include "SensorExtComponent.h"

#include <boost/enable_shared_from_this.hpp>
#include <boost/make_shared.hpp>

#include <iostream>

struct SensorForeign: public SensorExtComponent
                    , public Sensor
                    , public boost::enable_shared_from_this<SensorForeign>
{
  boost::shared_ptr<SensorCB> cb;
  boost::shared_ptr<asd::channels::ISingleThreaded> st;

  void GetAPI(boost::shared_ptr<Sensor>* api)
  {
    *api = shared_from_this();
  }
  void RegisterCB(boost::shared_ptr<SensorCB> cb)
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

boost::shared_ptr<SensorInterface> SensorExtComponent::GetInstance()
{
  return boost::make_shared<SensorForeign>();
}
void SensorExtComponent::ReleaseInstance()
{
}
