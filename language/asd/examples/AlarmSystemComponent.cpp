#include "AlarmSystemComponent.h"
#include "AlarmComponent.h"
#include "SensorComponent.h"
#include "SirenComponent.h"


#include "asdSingleThreaded.h"
#include "asdUsedServiceRef.h"
#include "asdDiagnostics.h"

#include <boost/bind.hpp>
#include <vector>
#include <set>

using namespace asd_0;

namespace AlarmSystemImplScope
{
  class Context;
  class Context: public asd_0::SingleThreadedContext/*NoDpc*/
  {
  public:
    boost::shared_ptr<ConsoleCB> m_consoleConsoleCB;
    void Setconsole(const boost::shared_ptr<ConsoleCB>&);
    ConsoleCB& GetconsoleConsoleCB() const;
#if 0
    Console::void GetconsoleConsoleAPIvoid() const;
    void SetconsoleConsoleAPIvoid(Console::void api);
#else
    void SetconsoleConsoleAPIvoid();
#endif

    boost::shared_ptr<AlarmComponent> m_alarm;
    boost::shared_ptr<SensorInterface> m_sensor;
    boost::shared_ptr<SirenInterface> m_siren;


  public:
    Context* Self() { return this; }
    
  private:
    Context(const Context&);
    Context& operator = (const Context&);
    
  public:
    Context();
    virtual ~Context();
  };

  class Component: public AlarmSystemComponent
  {
  private:
    Context m_Context;

    Component(const Component&);
    Component& operator = (const Component&);
    
  public:
    Component();
    ~Component();
    
    virtual void GetAPI(boost::shared_ptr<ConsoleAPI>* api);
    virtual void RegisterCB(boost::shared_ptr<ConsoleCB> cb);
    virtual void GetCB(boost::shared_ptr<ConsoleCB>* cb);
    virtual void RegisterAPI(boost::shared_ptr<ConsoleAPI> api);
#if 0
    virtual void GetconsoleInterface(boost::shared_ptr<ConsoleInterface>* intf);
#endif

    virtual void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> cb);
  };

  Context::Context()
  : asd_0::SingleThreadedContext/*NoDpc*/()

  {
    boost::shared_ptr<ConsoleInterface> m_console;
    // m_console = ConsoleComponent::GetInstance();

    m_alarm = AlarmComponent::GetInstance();
    m_sensor = SensorComponent::GetInstance();
    m_siren = SirenComponent::GetInstance();

    //bindings:
    {
      boost::shared_ptr<SensorCB> api;
      m_alarm->GetCBsensor(&api);
      m_sensor->RegisterCB(api);
      boost::shared_ptr<SensorAPI> cb;
      m_sensor->GetAPI(&cb);
      m_alarm->RegisterAPIsensor(cb);
    }
    {
      boost::shared_ptr<SirenCB> api;
      m_alarm->GetCBsiren(&api);
      m_siren->RegisterCB(api);
      boost::shared_ptr<SirenAPI> cb;
      m_siren->GetAPI(&cb);
      m_alarm->RegisterAPIsiren(cb);
    }

  }
  
  Context::~Context()
  {
    // ConsoleComponent::ReleaseInstance();

  }
  

  
  void Context::Setconsole(const boost::shared_ptr<ConsoleCB>& cb)
  {
    if (m_consoleConsoleCB && cb)
    {
      ASD_ILLEGAL("AlarmSystem", "", "ConsoleCB", "");
    }
    m_consoleConsoleCB = cb;
  }
  
  ConsoleCB& Context::GetconsoleConsoleCB() const
  {
    return *m_consoleConsoleCB;
  }
  
#if 0
  ConsoleAPI::void Context::GetconsoleConsoleAPIvoid() const
  {
    return m_consoleConsoleAPIvoid;
  }
#endif
  
  void Context::SetconsoleConsoleAPIvoid()
  {
#if 0
    m_consoleConsoleAPIvoid = value;
#endif
    unblock();
  }


  Component::Component()
  : m_Context()

  {
    ASD_TRACE_ENTER("AlarmSystem", "", "", "");
    
    ASD_TRACE_EXIT("AlarmSystem", "", "", "");
  }
  
  Component::~Component()
  {
    ASD_TRACE_ENTER("AlarmSystem", "", "", "");
    
    ASD_TRACE_EXIT("AlarmSystem", "", "", "");
  }

  void Component::GetAPI(boost::shared_ptr<ConsoleAPI>* api)
  {
        m_Context.m_alarm->GetAPIconsole(api);

  }
  
  void Component::RegisterCB(boost::shared_ptr<ConsoleCB> cb)
  {
        m_Context.m_alarm->RegisterCBconsole(cb);

  }
  
  void Component::GetCB(boost::shared_ptr<ConsoleCB>* /*cb*/)
  {
    // empty
  }
  
  void Component::RegisterAPI(boost::shared_ptr<ConsoleAPI> /*api*/)
  {
    // empty
  }


  void Component::RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> cb)
  {
    m_Context.setISingleThreaded(cb);
  }

}

boost::shared_ptr<ConsoleInterface> AlarmSystemComponent::GetInstance()
{
  return boost::shared_ptr<ConsoleInterface>(new AlarmSystemImplScope::Component);
}


void AlarmSystemComponent::ReleaseInstance()
{
}
