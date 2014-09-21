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
    (map
     (lambda (instance)
      (let ((name (.name instance)))
        (->string (list name "()"))))
     ((compose .elements .instances) model)))
, #(map-binds #{#.port-name (#.instance ) #}  (filter bind-port? ((compose .elements .bindings) model)) "\n, ")
{
#(map-binds #{connect(#.provided ,#.required );
#} (filter (negate bind-port?) ((compose .elements .bindings) model))) }
}
