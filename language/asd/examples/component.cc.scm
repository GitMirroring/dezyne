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
"  class %(*scoped-api*)Proxy: public %(*api-class*)
  {
    Context& m_Context;
    
  public:
    %(*scoped-api*)Proxy(Context& context);
%(map-port-events \"
    virtual %(*interface*)::%(*type*) %(*event*)();
\"
    port (port-events port))
  private:
    %(*scoped-api*)Proxy& operator = (const %(*scoped-api*)Proxy& other);
    %(*scoped-api*)Proxy(const %(*scoped-api*)Proxy& other);
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
