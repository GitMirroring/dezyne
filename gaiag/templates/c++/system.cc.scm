##include "component-#.model -c3.hh"

template<typename Port>
void connect(Port& provided, Port& required)
{
  provided.out = required.out;
  required.in = provided.in;
}

namespace component
{
#.model ::#.model ()
: #((->join  "\n, ")
    (map (init-instance #{ #name ()#})
         ((compose .elements .instances) model)))
, #((->join  "\n, ")
    (map (init-bind model #{ #port(#instance)#})
         (filter bind-port? ((compose .elements .bindings) model))))
{
 # (map (connect-ports model #{
    connect(#provided , #required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }
}
