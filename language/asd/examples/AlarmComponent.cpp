#include "AlarmComponent.h"

#include "asdSingleThreaded.h"
#include "asdUsedServiceRef.h"
#include "asdDiagnostics.h"

#include <boost/bind.hpp>
#include <vector>
#include <set>

using namespace asd_0;

namespace AlarmImplScope
{
  class Context;
  class consoleConsoleAPIProxy: public ConsoleAPI
  {
    Context& m_Context;
    
  public:
    consoleConsoleAPIProxy(Context& context);
    virtual void arm();
    virtual void disarm();

    
  private:
    consoleConsoleAPIProxy& operator = (const consoleConsoleAPIProxy& other);
    consoleConsoleAPIProxy(const consoleConsoleAPIProxy& other);
  };
  class sensorSensorCBProxy: public SensorCB
  {
    Context& m_Context;
    
  public:
    sensorSensorCBProxy(Context& context);
    virtual void triggered();
    virtual void disabled();

    
  private:
    sensorSensorCBProxy& operator = (const sensorSensorCBProxy& other);
    sensorSensorCBProxy(const sensorSensorCBProxy& other);
  };
  class sirenSirenCBProxy: public SirenCB
  {
    Context& m_Context;
    
  public:
    sirenSirenCBProxy(Context& context);

    
  private:
    sirenSirenCBProxy& operator = (const sirenSirenCBProxy& other);
    sirenSirenCBProxy(const sirenSirenCBProxy& other);
  };

  struct Alarm
  {
  enum States
  {
    Disarmed,
    Armed,
    Triggered,
    Disarming,
   
  };
  };

  class State : public Alarm
  {
  public:
    State();
    ~State() {}
    static State& instance();
#if 0
    void Processvoid(Context& context, ConsoleCB::void stimulus);
#endif
        void consoleConsolearm(Context& context);
    void consoleConsoledisarm(Context& context);

#if 0
    void Processvoid(Context& context, SensorAPI::void stimulus);
#endif
        void sensorSensortriggered(Context& context);
    void sensorSensordisabled(Context& context);

#if 0
    void Processvoid(Context& context, SirenAPI::void stimulus);
#endif
    

    protected:
    std::string m_TypeName;
    
  private:
    State& operator = (const State& other);
    State(const State& other);

  };

class State;
  class Context: public asd_0::SingleThreadedContext
  {
  public:
    boost::shared_ptr<ConsoleCB> m_consoleConsoleCB;
#if 0
    Console::void m_consoleConsoleAPIvoid;
#endif
    void Setconsole(const boost::shared_ptr<ConsoleCB>&);
    ConsoleCB& GetconsoleConsoleCB() const;
#if 0
    Console::void GetconsoleConsoleAPIvoid() const;
    void SetconsoleConsoleAPIvoid(Console::void api);
#else
    void SetconsoleConsoleAPIvoid();
#endif
    boost::shared_ptr<SensorAPI> m_sensorSensorAPI;
#if 0
    Sensor::void m_sensorSensorCBvoid;
#endif
    void Setsensor(const boost::shared_ptr<SensorAPI>&);
    SensorAPI& GetsensorSensorAPI() const;
#if 0
    Sensor::void GetsensorSensorCBvoid() const;
    void SetsensorSensorCBvoid(Sensor::void cb);
#else
    void SetsensorSensorCBvoid();
#endif
    boost::shared_ptr<SirenAPI> m_sirenSirenAPI;
#if 0
    Siren::void m_sirenSirenCBvoid;
#endif
    void Setsiren(const boost::shared_ptr<SirenAPI>&);
    SirenAPI& GetsirenSirenAPI() const;
#if 0
    Siren::void GetsirenSirenCBvoid() const;
    void SetsirenSirenCBvoid(Siren::void cb);
#else
    void SetsirenSirenCBvoid();
#endif


    State* m_State;
    State& getState();
  public:
    struct Predicates
    {
      Alarm::States state;
      bool sounding;

      Predicates()
      {
        state = Alarm::States::Disarmed;
        sounding = false;

      }
    };
    
  private:
    Predicates m_Predicates;
  public:
    const Predicates& predicates() const { return m_Predicates; }
    void predicates(const Predicates& p) { m_Predicates = p; }
  public:
    Context* Self() { return this; }
    
  private:
    Context(const Context&);
    Context& operator = (const Context&);
    
  public:
    Context();
    virtual ~Context();
  };

  class Component: public AlarmComponent
  {
  private:
    Context m_Context;
    boost::shared_ptr<consoleConsoleAPIProxy> m_consoleConsoleAPIProxy;
    boost::shared_ptr<sensorSensorCBProxy> m_sensorSensorCBProxy;
    boost::shared_ptr<sirenSirenCBProxy> m_sirenSirenCBProxy;

    Component(const Component&);
    Component& operator = (const Component&);
    
  public:
    Component();
    ~Component();
    
    virtual void GetAPIconsole(boost::shared_ptr<ConsoleAPI>* api);
    virtual void RegisterCBconsole(boost::shared_ptr<ConsoleCB> cb);
#if 0
    virtual void GetconsoleInterface(boost::shared_ptr<ConsoleInterface>* intf);
#endif
    virtual void GetCBsensor(boost::shared_ptr<SensorCB>* cb);
    virtual void RegisterAPIsensor(boost::shared_ptr<SensorAPI> api);
#if 0
    virtual void GetsensorInterface(boost::shared_ptr<SensorInterface>* intf);
#endif
    virtual void GetCBsiren(boost::shared_ptr<SirenCB>* cb);
    virtual void RegisterAPIsiren(boost::shared_ptr<SirenAPI> api);
#if 0
    virtual void GetsirenInterface(boost::shared_ptr<SirenInterface>* intf);
#endif

    virtual void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> cb);
  };

  consoleConsoleAPIProxy::consoleConsoleAPIProxy(Context& context)
  : m_Context(context)
  {
  }
    void consoleConsoleAPIProxy::arm()
  {
    m_Context.block();
    m_Context.getState().consoleConsolearm(m_Context);
    m_Context.awaitUnblock();
    
  }
  void consoleConsoleAPIProxy::disarm()
  {
    m_Context.block();
    m_Context.getState().consoleConsoledisarm(m_Context);
    m_Context.awaitUnblock();
    
  }
  
  
  sensorSensorCBProxy::sensorSensorCBProxy(Context& context)
  : m_Context(context)
  {
  }
    void sensorSensorCBProxy::triggered()
  {
    m_Context.defer(boost::bind(&State::sensorSensortriggered,
                    boost::bind(&Context::getState, &m_Context),
                    boost::ref(m_Context)));
    
  }
  void sensorSensorCBProxy::disabled()
  {
    m_Context.defer(boost::bind(&State::sensorSensordisabled,
                    boost::bind(&Context::getState, &m_Context),
                    boost::ref(m_Context)));
    
  }
  
  
  sirenSirenCBProxy::sirenSirenCBProxy(Context& context)
  : m_Context(context)
  {
  }
    
  

  Context::Context()
  : asd_0::SingleThreadedContext()
  , m_Predicates()
  , m_State(&State::instance())

  {
    boost::shared_ptr<ConsoleInterface> m_console;
    // m_console = ConsoleComponent::GetInstance();
    boost::shared_ptr<SensorInterface> m_sensor;
    // m_sensor = SensorComponent::GetInstance();
    boost::shared_ptr<SirenInterface> m_siren;
    // m_siren = SirenComponent::GetInstance();



  }
  
  Context::~Context()
  {
    // ConsoleComponent::ReleaseInstance();
    // SensorComponent::ReleaseInstance();
    // SirenComponent::ReleaseInstance();

  }
  
  State& Context::getState()
  {
    assert(m_State);
    return *m_State;
  }
  

  
  void Context::Setconsole(const boost::shared_ptr<ConsoleCB>& cb)
  {
    if (m_consoleConsoleCB && cb)
    {
      ASD_ILLEGAL("Alarm", "", "ConsoleCB", "");
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
  void Context::Setsensor(const boost::shared_ptr<SensorAPI>& cb)
  {
    if (m_sensorSensorAPI && cb)
    {
      ASD_ILLEGAL("Alarm", "", "SensorAPI", "");
    }
    m_sensorSensorAPI = cb;
  }
  
  SensorAPI& Context::GetsensorSensorAPI() const
  {
    return *m_sensorSensorAPI;
  }
  
#if 0
  SensorCB::void Context::GetsensorSensorCBvoid() const
  {
    return m_sensorSensorCBvoid;
  }
#endif
  
  void Context::SetsensorSensorCBvoid()
  {
#if 0
    m_sensorSensorCBvoid = value;
#endif
    unblock();
  }
  void Context::Setsiren(const boost::shared_ptr<SirenAPI>& cb)
  {
    if (m_sirenSirenAPI && cb)
    {
      ASD_ILLEGAL("Alarm", "", "SirenAPI", "");
    }
    m_sirenSirenAPI = cb;
  }
  
  SirenAPI& Context::GetsirenSirenAPI() const
  {
    return *m_sirenSirenAPI;
  }
  
#if 0
  SirenCB::void Context::GetsirenSirenCBvoid() const
  {
    return m_sirenSirenCBvoid;
  }
#endif
  
  void Context::SetsirenSirenCBvoid()
  {
#if 0
    m_sirenSirenCBvoid = value;
#endif
    unblock();
  }


  Component::Component()
  : m_Context()
, m_consoleConsoleAPIProxy(new consoleConsoleAPIProxy(m_Context))
, m_sensorSensorCBProxy(new sensorSensorCBProxy(m_Context))
, m_sirenSirenCBProxy(new sirenSirenCBProxy(m_Context))

  {
    ASD_TRACE_ENTER("Alarm", "", "", "");
    
    ASD_TRACE_EXIT("Alarm", "", "", "");
  }
  
  Component::~Component()
  {
    ASD_TRACE_ENTER("Alarm", "", "", "");
    
    ASD_TRACE_EXIT("Alarm", "", "", "");
  }

  void Component::GetAPIconsole(boost::shared_ptr<ConsoleAPI>* api)
  {
    *api = m_consoleConsoleAPIProxy;
  }
  
  void Component::RegisterCBconsole(boost::shared_ptr<ConsoleCB> cb)
  {
    m_Context.Setconsole(cb);
  }
  void Component::GetCBsensor(boost::shared_ptr<SensorCB>* cb)
  {
    *cb = m_sensorSensorCBProxy;
  }
  
  void Component::RegisterAPIsensor(boost::shared_ptr<SensorAPI> api)
  {
    m_Context.Setsensor(api);
  }
  void Component::GetCBsiren(boost::shared_ptr<SirenCB>* cb)
  {
    *cb = m_sirenSirenCBProxy;
  }
  
  void Component::RegisterAPIsiren(boost::shared_ptr<SirenAPI> api)
  {
    m_Context.Setsiren(api);
  }


  void Component::RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> cb)
  {
    m_Context.setISingleThreaded(cb);
  }

#if 0
  void State::Processvoid(Context& /*context*/, ConsoleCB::void /* stimulus */)
  {
  }
#endif
  
  void State::consoleConsolearm(Context& context)
  {
    ASD_TRACE_ENTER("Alarm", "State", "ConsoleCB", "arm");
    
    Context::Predicates predicate = context.predicates();

  if (predicate.state == Disarmed)
{
    {
          context.GetsensorSensorAPI().enable();
    predicate.state = Alarm::States::Armed;
        context.SetconsoleConsoleAPIvoid();

}


}
else if (predicate.state == Armed)
{
            ASD_ILLEGAL("Alarm", "State", "ConsoleCB", "arm");


}
else if (predicate.state == Disarming)
{
            ASD_ILLEGAL("Alarm", "State", "ConsoleCB", "arm");


}
else if (predicate.state == Triggered)
{
            ASD_ILLEGAL("Alarm", "State", "ConsoleCB", "arm");


}



    context.predicates(predicate);
    ASD_TRACE_EXIT("Alarm", "State", "ConsoleCB", "arm");
  }
  
  void State::consoleConsoledisarm(Context& context)
  {
    ASD_TRACE_ENTER("Alarm", "State", "ConsoleCB", "disarm");
    
    Context::Predicates predicate = context.predicates();

  if (predicate.state == Disarmed)
{
            ASD_ILLEGAL("Alarm", "State", "ConsoleCB", "disarm");


}
else if (predicate.state == Armed)
{
    {
          context.GetsensorSensorAPI().disable();
    predicate.state = Alarm::States::Disarming;
        context.SetconsoleConsoleAPIvoid();

}


}
else if (predicate.state == Disarming)
{
            ASD_ILLEGAL("Alarm", "State", "ConsoleCB", "disarm");


}
else if (predicate.state == Triggered)
{
    {
          context.GetsensorSensorAPI().disable();
    predicate.sounding = false;
        predicate.state = Alarm::States::Disarming;
        context.SetconsoleConsoleAPIvoid();

}


}



    context.predicates(predicate);
    ASD_TRACE_EXIT("Alarm", "State", "ConsoleCB", "disarm");
  }
  

#if 0
  void State::Processvoid(Context& /*context*/, SensorAPI::void /* stimulus */)
  {
  }
#endif
  
  void State::sensorSensortriggered(Context& context)
  {
    ASD_TRACE_ENTER("Alarm", "State", "SensorAPI", "triggered");
    
    Context::Predicates predicate = context.predicates();

  if (predicate.state == Disarmed)
{
            ASD_ILLEGAL("Alarm", "State", "SensorAPI", "triggered");


}
else if (predicate.state == Armed)
{
    {
          context.GetconsoleConsoleCB().detected();
        context.GetsirenSirenAPI().turnon();
    predicate.sounding = true;
        predicate.state = Alarm::States::Triggered;
        context.SetsensorSensorCBvoid();

}


}
else if (predicate.state == Disarming)
{
    {
  
}


}
else if (predicate.state == Triggered)
{
            ASD_ILLEGAL("Alarm", "State", "SensorAPI", "triggered");


}



    context.predicates(predicate);
    ASD_TRACE_EXIT("Alarm", "State", "SensorAPI", "triggered");
  }
  
  void State::sensorSensordisabled(Context& context)
  {
    ASD_TRACE_ENTER("Alarm", "State", "SensorAPI", "disabled");
    
    Context::Predicates predicate = context.predicates();

  if (predicate.state == Disarmed)
{
            ASD_ILLEGAL("Alarm", "State", "SensorAPI", "disabled");


}
else if (predicate.state == Armed)
{
            ASD_ILLEGAL("Alarm", "State", "SensorAPI", "disabled");


}
else if (predicate.state == Disarming)
{
    {
  if (predicate.sounding)
{
            context.GetconsoleConsoleCB().deactivated();
    predicate.state = Alarm::States::Disarmed;
        predicate.sounding = false;
        context.SetsensorSensorCBvoid();


}
else
{
            context.GetconsoleConsoleCB().deactivated();
    predicate.state = Alarm::States::Disarmed;
        context.SetsensorSensorCBvoid();


}

}


}
else if (predicate.state == Triggered)
{
            ASD_ILLEGAL("Alarm", "State", "SensorAPI", "disabled");


}



    context.predicates(predicate);
    ASD_TRACE_EXIT("Alarm", "State", "SensorAPI", "disabled");
  }
  

#if 0
  void State::Processvoid(Context& /*context*/, SirenAPI::void /* stimulus */)
  {
  }
#endif
  



}

boost::shared_ptr<AlarmComponent> AlarmComponent::GetInstance()
{
  return boost::shared_ptr<AlarmComponent>(new AlarmImplScope::Component);
}



void AlarmComponent::ReleaseInstance()
{
}
