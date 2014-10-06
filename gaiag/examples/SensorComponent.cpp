#include "SensorComponent.h"

struct SensorForeign: public SensorComponent
                    , public Sensor
                    , public boost::enable_shared_from_this<SensorForeign>
{
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

  void enable()
  {
    cb->triggered();
    st->processCBs;
  }
  void disable()
  {
    cb->disabled();
    st->processCBs;
  }
};

boost::shared_ptr<SensorInterface> SensorComponent::GetInstance()
{
  boost::make_shared<SensorForeign>();
}
void SensorComponent::ReleaseInstance()
{
}
