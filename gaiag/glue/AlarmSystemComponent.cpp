#include "AlarmSystemComponent.h"

#include "locator.h"
#include "runtime.h"

#include "AlarmSystem.hh"

#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/enable_shared_from_this.hpp>
#include <boost/make_shared.hpp>

namespace dezyne
{
  inline void push(boost::shared_ptr<asd::channels::ISingleThreaded> st, boost::function<void()> cb)
  {
    cb(); if(st) st->processCBs();
  }

  struct AlarmSystemGlue
  : public AlarmSystemComponent
  , public boost::enable_shared_from_this<AlarmSystemGlue>
  {
    ::AlarmSystem component;




    struct Console
    : public IConsole
    {
      ::IConsole& api;
      Console(::IConsole& api)
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


    boost::shared_ptr<IConsole> api_IConsole;

    boost::shared_ptr<IConsoleCB> cb_IConsoleCB;

    boost::shared_ptr<asd::channels::ISingleThreaded> st;

    AlarmSystemGlue (const locator& l)
    : component(l)
    , api_IConsole(boost::make_shared<Console>(boost::ref(component.console)))

    {
      component.console.out.detected = boost::bind(push, boost::ref(st), boost::function<void()>(boost::bind(&IConsoleCB::Tripped, boost::ref(cb_IConsoleCB))));
      component.console.out.deactivated = boost::bind(push, boost::ref(st), boost::function<void()>(boost::bind(&IConsoleCB::Deactivated, boost::ref(cb_IConsoleCB))));

    }

    void GetAPI(boost::shared_ptr<IConsole>* api)
    {
      *api = api_IConsole;
    }



    void RegisterCB(boost::shared_ptr<IConsoleCB> cb)
    {
      cb_IConsoleCB = cb;
    }


    void RegisterCB (boost::shared_ptr<asd::channels::ISingleThreaded> st)
    {
      this->st = st;
    }
  };

  dezyne::locator dezyne_locator;
  dezyne::runtime dezyne_runtime;

  boost::shared_ptr<IConsoleInterface> AlarmSystemComponent::GetInstance ()
  {
    dezyne_locator.set(dezyne_runtime);
    return boost::make_shared<AlarmSystemGlue> (dezyne_locator);
  }
  void AlarmSystemComponent::ReleaseInstance () {}
}
