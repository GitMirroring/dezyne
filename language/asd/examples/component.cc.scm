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
%(map-port-events \"
    virtual %(if (eq? 'void (*type*)) (*type*) (list (*interface*) \\\"::\\\" (*type*))) %(*event*)();\"
    port (filter (event-dir-matches? port) (port-events port)))
  private:
    %(*port*)%(*interface*)%(*api*)Proxy& operator = (const %(*port*)%(*interface*)%(*api*)Proxy& other);
    %(*port*)%(*interface*)%(*api*)Proxy(const %(*port*)%(*interface*)%(*api*)Proxy& other);
  };
" (component-ports (component ast)))

%(*state-class*)
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
