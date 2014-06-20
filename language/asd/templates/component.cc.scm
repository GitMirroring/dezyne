##include "#.component Component.h"

##include "asdSingleThreaded.h"
##include "asdUsedServiceRef.h"
##include "asdDiagnostics.h"

##include <boost/bind.hpp>
##include <vector>
##include <set>

using namespace asd_0;

namespace #.component ImplScope
{
  class Context;
#(map-ports
#{  class #.port #.interface #.api Proxy: public #.interface #.api 
  {
    Context& m_Context;
    
  public:
    #.port #.interface #.api Proxy(Context& context);
#(map-port-events 
#{
    virtual #(if (eq? 'void .type ) .type (list .interface "::" .type ))  #.event ();
#}  port (filter (event-dir-matches? port) (port-events port)))
  private:
/*
examples/component.cc.scm:28: here */
    #.port #.interface #.api Proxy& operator = (const #.port #.interface #.api Proxy& other);
    #.port #.interface #.api Proxy(const #.port #.interface #.api Proxy& other);
  };
#} (component-ports (component ast)))

  struct #.component 
  {
    #(->string (map declare-enum (behaviour-types (component-behaviour (component ast)))))
  };

  class State : public #.component 
  {
  public:
    State();
    ~State() {}
    static State& instance();
#(map-ports
#{##if 0
    void Processvoid(Context& context, #.interface #.callback ::void stimulus);
##endif

#(map-port-events 
#{
    void #.port #.interface #.event (Context& context);
#}
    port (filter (event-dir-matches? port) (port-events port)))
#} (component-ports (component ast)))

    protected:
    std::string m_TypeName;
    
  private:
    State& operator = (const State& other);
    State(const State& other);
/*
examples/component.cc.scm:63: TODO function-definitions */
  };
  class State;
  class Context: public asd_0::SingleThreadedContext#.no-dpc 
  {
  public:
#(map-ports
#{    boost::shared_ptr<#.interface #.callback > m_#.port #.interface #.callback ;
#.if-typed 
    #.interface ::#.type  m_#.port #.interface #.api #.type ;
#.endif-typed 
    void Set#.port (const boost::shared_ptr<#.interface #.callback >&);
    #.interface #.callback & Get#.port #.interface #.callback () const;
#.if-typed 
    #.interface ::#.type  Get#.port #.interface #.api #.type () const;
    void Set#.port #.interface #.api #.type (#.interface ::#.type #.ap );
#.else-typed 
    void Set#.port #.interface #.api #.type ();
#.endif-typed 
#} (component-ports (component ast)))

/*
examples/component.cc.scm:85: TODO instances */

# (string-if (component-behaviour (component ast))
#{
    State* m_State;
    State& getState();
  public:
    struct Predicates
    {
# (map-variables
#{      #.state-type  #.variable ;
#} (behaviour-variables (component-behaviour (component ast))))
      Predicates()
      {
# (map-variables
#{        #.variable  = #.value ;
#} (behaviour-variables (component-behaviour (component ast))))
      }
    };
    
  private:
    Predicates m_Predicates;
  public:
    const Predicates& predicates() const { return m_Predicates; }
    void predicates(const Predicates& p) { m_Predicates = p; }
#}
)
  public:
    Context* Self() { return this; }
    
  private:
    Context(const Context&);
    Context& operator = (const Context&);
    
  public:
    Context();
    virtual ~Context();
  };

  class Component: public #.component Component
  {
  private:
    Context m_Context;
#(map-ports
#{    boost::shared_ptr<#.port #.interface #.api Proxy> m_#.port #.interface #.api Proxy;
#} (component-ports (component ast)))
    Component(const Component&);
    Component& operator = (const Component&);
    
  public:
    Component();
    ~Component();
    
#(map-ports
#{#(string-if (component-bottom? (component ast))
#{
    virtual void Get#.api (boost::shared_ptr<#.interface #.api >* #.ap );
    virtual void Register#.callback (boost::shared_ptr<#.interface #.callback > #.cb );
    virtual void Get#.callback (boost::shared_ptr<#.interface #.callback >* #.cb );
    virtual void Register#.api (boost::shared_ptr<#.interface #.api > #.ap );
##if 0
    virtual void Get#.port Interface(boost::shared_ptr<#.interface Interface>* intf);
##endif
#}
#{
    virtual void Get#.api #.port (boost::shared_ptr<#.interface #.api >* #.ap );
    virtual void Register#.callback #.port (boost::shared_ptr<#.interface #.callback > #.cb );
##if 0
    virtual void Get#.port Interface(boost::shared_ptr<#.interface Interface>* intf);
##endif
#})#}  (component-ports (component ast)))
    virtual void Register#.callback (boost::shared_ptr<asd::channels::ISingleThreaded> cb);
  };

// if has behaviour
# (map-ports
#{  #.port #.interface #.api Proxy::#.port #.interface #.api Proxy(Context& context)
  : m_Context(context)
  {
  }
#(map-port-events
#{

#(string-if (eq? (port-direction port) 'provides)
#{
  #.return-interface-type  #.port #.interface #.api Proxy::#.event ()
  {
    m_Context.block();
    m_Context.getState().#.port #.interface #.event (m_Context);
    m_Context.awaitUnblock();
    #return-context-get 
  }
#}
#{
  #.return-interface-type  #.port #.interface #.api Proxy::#.event ()
  {
    m_Context.defer(boost::bind(&State::#.port #.interface #.event ,
                    boost::bind(&Context::getState, &m_Context),
                    boost::ref(m_Context)));
    #return-context-get 
  }
#})

#} port (filter (event-dir-matches? port) (port-events port)))
  
#} (component-ports (component ast)))

  Context::Context()
  : asd_0::SingleThreadedContext#.no-dpc ()
#(string-if (component-behaviour? (component ast))
"  , m_Predicates()
  , m_State(&State::instance())
")
  {
#(map-ports
#{     boost::shared_ptr<#.interface Interface> m_#.port ;
    // m_#.port  = #.interface Component::GetInstance();
#} (component-ports (component ast)))
/*
examples/component.cc.scm:202: TODO: constructor-instances */
/*
examples/component.cc.scm:204 TODO: binding */
  }
  
  Context::~Context()
  {
# (map-ports
#{    // #.interface Component::ReleaseInstance();
#} (component-ports (component ast)))
  }
  
#(string-if (component-behaviour? (component ast))
#{
  State& Context::getState()
  {
    assert(m_State);
    return *m_State;
  }
#})
  
#(map-ports
#{
  void Context::Set#.port (const boost::shared_ptr<#.interface #.callback >& cb)
  {
    if (m_#.port #.interface #.callback && cb)
    {
      ASD_ILLEGAL("#.component ", "", "#.interface #.callback ", "");
    }
    m_#.port #.interface #.callback = cb;
  }
  
  #.interface #.callback & Context::Get#.port #.interface #.callback () const
  {
    return *m_#.port #.interface #.callback ;
  }
  
#.if-typed 
  #.interface #.api ::#.type  Context::Get#.port #.interface #.api #.type () const
  {
    return m_#.port #.interface #.api #.type ;
  }
#.endif-typed 
  
  void Context::Set#(list .port .interface .api .type)(#.parameters )
  {
#.if-typed 
    m_#.port #.interface #.api #.type  = value;
#.endif-typed 
    unblock();
  }
#} (component-ports (component ast)))

  Component::Component()
  : m_Context()
#(string-if (component-behaviour? (component ast))
#{
#(map-ports
#{  , m_#.port #.interface #.api Proxy(new #.port #.interface #.api Proxy(m_Context))

#}  (component-ports (component ast)))
#})
  {
    ASD_TRACE_ENTER("#.component ", "", "", "");
    
    ASD_TRACE_EXIT("#.component ", "", "", "");
  }
  
  Component::~Component()
  {
    ASD_TRACE_ENTER("#.component ", "", "", "");
    
    ASD_TRACE_EXIT("#.component ", "", "", "");
  }

#(map-ports
#{
#(string-if (component-bottom? (component ast))
#{
  void Component::Get#.api (boost::shared_ptr<#.interface #.api >* #.ap )
  {
    *#.ap = m_#.port #.interface #.api Proxy;
  }
  
  void Component::Register#.callback (boost::shared_ptr<#.interface #.callback > #.cb )
  {
    m_Context.Set#.port (#.cb );
  }
  
  void Component::Get#.callback (boost::shared_ptr<#.interface #.callback >* /*#.cb */)
  {
    // empty
  }
  
  void Component::Register#.api (boost::shared_ptr<#.interface #.api > /*#.ap */)
  {
    // empty
  }
#}
#{
  void Component::Get#.api #.port (boost::shared_ptr<#.interface #.api >* #.ap )
  {
    *#.ap = m_#.port #.interface #.api Proxy;
  }
  
  void Component::Register#.callback #.port (boost::shared_ptr<#.interface #.callback > #.cb )
  {
    m_Context.Set#.port (#.cb );
  }
#}
)#}  (component-ports (component ast)))

  void Component::Register#.callback (boost::shared_ptr<asd::channels::ISingleThreaded> #.cb )
  {
    m_Context.setISingleThreaded(#.cb );
  }

#(string-if (component-behaviour? (component ast))
#{
#(map-ports
#{##if 0
  void State::Processvoid(Context& /*context*/, #.interface #.callback ::void /* stimulus */)
  {
  }
##endif

#(map-port-events
#{
  void State::#.port #.interface #.event (Context& context)
  {
    ASD_TRACE_ENTER("#.component ", "State", "#.interface #.callback ", "#.event ");
    
    Context::Predicates predicate = context.predicates();

#.statement

    context.predicates(predicate);
    ASD_TRACE_EXIT("#.component ", "State", "#.interface #.callback ", "#.event ");
  }#}
    port (filter (event-dir-matches? port) (port-events port)))

#}  (component-ports (component ast)))
#})

/*
examples/component.cc.scm:340: TODO function-definitions */

}

#(string-if (component-bottom? (component ast))
#{
#(map-ports
#{boost::shared_ptr<#.interface Interface> #.component Component::GetInstance()
{
  return boost::shared_ptr<#.interface Interface>(new #.component ImplScope::Component);
}
#} (component-ports (component ast)))
#}
#{
boost::shared_ptr<#.component Component> #.component Component::GetInstance()
{
  return boost::shared_ptr<#.component Component>(new #.component ImplScope::Component);
}
#})

void #.component Component::ReleaseInstance()
{
}

