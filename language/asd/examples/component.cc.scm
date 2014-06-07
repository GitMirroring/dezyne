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
\"    void %(port-name (*port*))%(*interface*)%(*event*)(Context& context);
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
%(*context-class*)
%(*component-class*)
%(*proxy-methods*)
%(*context-methods*)
%(*component-methods*)
%(*state-methods*)
%(*function-definitions*)
}

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
