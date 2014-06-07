#include "%(*component*)Component.h"

#include "asdSingleThreaded.h"
#include "asdUsedServiceRef.h"
#include "asdDiagnostics.h"

#include <boost/bind.hpp>
#include <vector>
#include <set>

using namespace asd_0;

namespace %(*component*)ImplScope
{
  class Context;
%(map-ports
"  class %(*port*)%(*interface*)%(*api*)Proxy: public %(*interface*)%(*api*)
  {
    Context& m_Context;
    
  public:
    %(*port*)%(*interface*)%(*api*)Proxy(Context& context);
%(map-port-events 
\"    virtual %(if (eq? 'void (*type*)) (*type*) (list (*interface*) \\\"::\\\" (*type*))) %(*event*)();
\"
    port (filter (event-dir-matches? port) (port-events port)))
  private:
    %(*port*)%(*interface*)%(*api*)Proxy& operator = (const %(*port*)%(*interface*)%(*api*)Proxy& other);
    %(*port*)%(*interface*)%(*api*)Proxy(const %(*port*)%(*interface*)%(*api*)Proxy& other);
  };
" (component-ports (component ast)))

  struct %(*component*)
  {
    %(->string (map enum->string (behaviour-types (component-behaviour (component ast)))))
  };

  class State : public %(*component*)
  {
  public:
    State();
    ~State() {}
    static State& instance();
%(map-ports
"#if 0
    void Processvoid(Context& context, ConsoleCB::void stimulus);
#endif

%(map-port-events 
\"    void %(*port*)%(*interface*)%(*event*)(Context& context);
\"
    port (filter (event-dir-matches? port) (port-events port)))
" (component-ports (component ast)))

    protected:
    std::string m_TypeName;
    
  private:
    State& operator = (const State& other);
    State(const State& other);
%(*function-declarations*)
  };
class State;
  class Context: public asd_0::SingleThreadedContext%(*no-dpc*)
  {
  public:
%(map-ports
"    boost::shared_ptr<%(*interface*)%(*callback*)> m_%(*port*)%(*interface*)%(*callback*);
%(*if-type*)
    %(*interface*)::%(*type*) m_%(*port*)%(*interface*)%(*api*)%(*type*);
%(*endif-type*)
    void Set%(*port*)(const boost::shared_ptr<%(*interface*)%(*callback*)>&);
    %(*interface*)%(*callback*)& Get%(*port*)%(*interface*)%(*callback*)() const;
%(*if-type*)
    %(*interface*)::%(*type*) Get%(*port*)%(*interface*)%(*api*)%(*type*)() const;
    void Set%(*port*)%(*interface*)%(*api*)%(*type*)(%(*interface*)::%(*type*) %(*ap*));
%(*else-type*)
    void Set%(*port*)%(*interface*)%(*api*)%(*type*)();
%(*endif-type*)
" (component-ports (component ast)))

%(*instances*)
% (string-if (component-behaviour (component ast))
"    State* m_State;
    State& getState();
  public:
    struct Predicates
    {
% (map-variables
\"      %(*state-type*) %(*variable*);
\" (behaviour-variables (component-behaviour (component ast))))
      Predicates()
      {
% (map-variables
\"        %(*variable*) = %(*value*);
\" (behaviour-variables (component-behaviour (component ast))))
      }
    };
    
  private:
    Predicates m_Predicates;
  public:
    const Predicates& predicates() const { return m_Predicates; }
    void predicates(const Predicates& p) { m_Predicates = p; }
"

"")    
  public:
    Context* Self() { return this; }
    
  private:
    Context(const Context&);
    Context& operator = (const Context&);
    
  public:
    Context();
    virtual ~Context();
  };

  class Component: public %(*component*)Component
  {
  private:
    Context m_Context;
%(map-ports
"    boost::shared_ptr<%(*port*)%(*interface*)%(*api*)Proxy> m_%(*port*)%(*interface*)%(*api*)Proxy;
" (component-ports (component ast)))
    Component(const Component&);
    Component& operator = (const Component&);
    
  public:
    Component();
    ~Component();
    
%(map-ports
"%(string-if (component-bottom? (component ast))
\"    virtual void Get%(*api*)(boost::shared_ptr<%(*interface*)%(*api*)>* %(*ap*));
    virtual void Register%(*callback*)(boost::shared_ptr<%(*interface*)%(*callback*)> %(*cb*));
    virtual void Get%(*callback*)(boost::shared_ptr<%(*interface*)%(*callback*)>* %(*cb*));
    virtual void Register%(*api*)(boost::shared_ptr<%(*interface*)%(*api*)> %(*ap*));
#if 0
    virtual void Get%(*port*)Interface(boost::shared_ptr<%(*interface*)Interface>* intf);
#endif
\"
\"    virtual void Get%(*api*)%(*port*)(boost::shared_ptr<%(*interface*)%(*api*)>* %(*ap*));
    virtual void Register%(*callback*)%(*port*)(boost::shared_ptr<%(*interface*)%(*callback*)> %(*cb*));
#if 0
    virtual void Get%(*port*)Interface(boost::shared_ptr<%(*interface*)Interface>* intf);
#endif
\")"  (component-ports (component ast)))
%(variable-unset! (module-variable (current-module) '*port-def*))
    virtual void Register%(*callback*)(boost::shared_ptr<asd::channels::ISingleThreaded> cb);
  };

%(*proxy-methods*)
%(*context-methods*)
%(*component-methods*)
%(*state-methods*)
%(*function-definitions*)

%(map-ports
"
boost::shared_ptr<%(*interface*)Interface> %(*component*)Component::GetInstance()
{
  return boost::shared_ptr<%(*interface*)Interface>(new %(*component*)ImplScope::Component);
}
" (component-ports (component ast)))

void %(*component*)Component::ReleaseInstance()
{
}
