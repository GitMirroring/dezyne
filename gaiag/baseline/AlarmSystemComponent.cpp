#include "AlarmSystemComponent.h"

#include "component-AlarmSystem-c3.hh"

#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/enable_shared_from_this.hpp>
#include <boost/make_shared.hpp>

inline void push(boost::shared_ptr<asd::channels::ISingleThreaded> st, boost::function<void()> cb)
{
  cb(); if(st) st->processCBs();
}

struct AlarmSystemGlue
: public AlarmSystemComponent
, public boost::enable_shared_from_this<AlarmSystemGlue>
{
  component::AlarmSystem component;




  struct Console
  : public ::Console
  {
    interface::IConsole& api;
    Console(interface::IConsole& api)
    : api(api)
    {}
    void SwitchOn()
    {
      return api.in.arm();
    }
    void SwitchOff()
    {
      return api.in.disarm();
    }
  };


  boost::shared_ptr<Console> api_Console;

  boost::shared_ptr<ConsoleCB> cb_ConsoleCB;

  boost::shared_ptr<asd::channels::ISingleThreaded> st;

  AlarmSystemGlue ()
  : component()
  , api_Console(boost::make_shared<Console>(boost::ref(component.console)))

  {
    component.console.out.detected = boost::bind(push, boost::ref(st), boost::function<void()>(boost::bind(&ConsoleCB::Tripped, boost::ref(cb_ConsoleCB))));
    component.console.out.deactivated = boost::bind(push, boost::ref(st), boost::function<void()>(boost::bind(&ConsoleCB::Deactivated, boost::ref(cb_ConsoleCB))));

  }

  void GetAPI(boost::shared_ptr< ::Console>* api)
  {
    *api = api_Console;
  }



  void RegisterCB(boost::shared_ptr< ::ConsoleCB> cb)
  {
    cb_ConsoleCB = cb;
  }


  void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded> st)
  {
    this->st = st;
  }
};

boost::shared_ptr<IConsoleInterface> AlarmSystemComponent::GetInstance ()
{
  return boost::make_shared<AlarmSystemGlue> ();
}
void AlarmSystemComponent::ReleaseInstance () {}
