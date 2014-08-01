#include "argument2Component.h"

#include "asdSingleThreaded.h"
#include "asdUsedServiceRef.h"
#include "asdDiagnostics.h"

#include <boost/bind.hpp>
#include <vector>
#include <set>

using namespace asd_0;

namespace argument2ImplScope
{
  class Context;
  class iIAPIProxy: public IAPI
  {
    Context& m_Context;
    
  public:
    iIAPIProxy(Context& context);
    virtual void e();

    
  private:
    iIAPIProxy& operator = (const iIAPIProxy& other);
    iIAPIProxy(const iIAPIProxy& other);
  };

  struct argument2
  {

  };

  class State : public argument2
  {
  public:
    State();
    ~State() {}
    static State& instance();
#if 0
    void Processvoid(Context& context, ICB::void stimulus);
#endif
        void iIe(Context& context);


    protected:
    std::string m_TypeName;
    
  private:
    State& operator = (const State& other);
    State(const State& other);
    bool g(Context& context, bool ga, bool gb);

  };

class State;
  class Context: public asd_0::SingleThreadedContext/*NoDpc*/
  {
  public:
    boost::shared_ptr<ICB> m_iICB;
#if 0
    I::void m_iIAPIvoid;
#endif
    void Seti(const boost::shared_ptr<ICB>&);
    ICB& GetiICB() const;
#if 0
    I::void GetiIAPIvoid() const;
    void SetiIAPIvoid(I::void api);
#else
    void SetiIAPIvoid();
#endif


    State* m_State;
    State& getState();
  public:
    struct Predicates
    {
      bool b;

      Predicates()
      {
        b = false;

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

  class Component: public argument2Component
  {
  private:
    Context m_Context;
    boost::shared_ptr<iIAPIProxy> m_iIAPIProxy;

    Component(const Component&);
    Component& operator = (const Component&);
    
  public:
    Component();
    ~Component();
    
    virtual void GetAPI(boost::shared_ptr<IAPI>* api);
    virtual void RegisterCB(boost::shared_ptr<ICB> cb);
    virtual void GetCB(boost::shared_ptr<ICB>* cb);
    virtual void RegisterAPI(boost::shared_ptr<IAPI> api);
#if 0
    virtual void GetiInterface(boost::shared_ptr<IInterface>* intf);
#endif

    virtual void RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> cb);
  };

  iIAPIProxy::iIAPIProxy(Context& context)
  : m_Context(context)
  {
  }
    void iIAPIProxy::e()
  {
    m_Context.block();
    m_Context.getState().iIe(m_Context);
    m_Context.awaitUnblock();
    
  }
  
  

  Context::Context()
  : asd_0::SingleThreadedContext/*NoDpc*/()
  , m_Predicates()
  , m_State(&State::instance())

  {
    boost::shared_ptr<IInterface> m_i;
    // m_i = IComponent::GetInstance();



  }
  
  Context::~Context()
  {
    // IComponent::ReleaseInstance();

  }
  
  State& Context::getState()
  {
    assert(m_State);
    return *m_State;
  }
  

  
  void Context::Seti(const boost::shared_ptr<ICB>& cb)
  {
    if (m_iICB && cb)
    {
      ASD_ILLEGAL("argument2", "", "ICB", "");
    }
    m_iICB = cb;
  }
  
  ICB& Context::GetiICB() const
  {
    return *m_iICB;
  }
  
#if 0
  IAPI::void Context::GetiIAPIvoid() const
  {
    return m_iIAPIvoid;
  }
#endif
  
  void Context::SetiIAPIvoid()
  {
#if 0
    m_iIAPIvoid = value;
#endif
    unblock();
  }


  Component::Component()
  : m_Context()
, m_iIAPIProxy(new iIAPIProxy(m_Context))

  {
    ASD_TRACE_ENTER("argument2", "", "", "");
    
    ASD_TRACE_EXIT("argument2", "", "", "");
  }
  
  Component::~Component()
  {
    ASD_TRACE_ENTER("argument2", "", "", "");
    
    ASD_TRACE_EXIT("argument2", "", "", "");
  }

  void Component::GetAPI(boost::shared_ptr<IAPI>* api)
  {
    *api = m_iIAPIProxy;
  }
  
  void Component::RegisterCB(boost::shared_ptr<ICB> cb)
  {
    m_Context.Seti(cb);
  }
  
  void Component::GetCB(boost::shared_ptr<ICB>* /*cb*/)
  {
    // empty
  }
  
  void Component::RegisterAPI(boost::shared_ptr<IAPI> /*api*/)
  {
    // empty
  }


  void Component::RegisterCB(boost::shared_ptr<asd::channels::ISingleThreaded> cb)
  {
    m_Context.setISingleThreaded(cb);
  }

#if 0
  void State::Processvoid(Context& /*context*/, ICB::void /* stimulus */)
  {
  }
#endif
  
  void State::iIe(Context& context)
  {
    ASD_TRACE_ENTER("argument2", "State", "ICB", "e");
    
    Context::Predicates predicate = context.predicates();

  if (true)
{
        predicate.b = !(b);
        predicate.b = g(context, c, c);
;
    if (c)
{
            context.GetiICB().f();


}


}



    context.predicates(predicate);
    ASD_TRACE_EXIT("argument2", "State", "ICB", "e");
  }
  


bool State::g(Context& context, bool ga, bool gb)
{
  Context::Predicates predicate = context.predicates();
            context.GetiICB().f();
return (ga) || (gb);

}

}

boost::shared_ptr<IInterface> argument2Component::GetInstance()
{
  return boost::shared_ptr<IInterface>(new argument2ImplScope::Component);
}


void argument2Component::ReleaseInstance()
{
}
