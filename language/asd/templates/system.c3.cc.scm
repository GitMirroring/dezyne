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
: #(map-instances #{#.instance () #} (gom:instances model) "\n, ")
, #(map-binds #{#.port-name (#.instance ) #}  (filter bind-port? (gom:binds model)) "\n, ")
{
#(map-binds #{connect(#.provided ,#.required );
#} (filter (negate bind-port?) (gom:binds model))) }
}
