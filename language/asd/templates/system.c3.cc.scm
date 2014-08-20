##include "#.model -c3.hh"

template<typename Port>
void connect(Port& provided, Port& required)
{
  provided.out = required.out;
  required.in = provided.in;
}

#.model ::#.model ()
: #(map-instances #{#.instance () #} (ast:instances model) "\n, ")
, #(map-binds #{#.port (#.instance ) #}  (filter bind-port? (ast:binds model)) "\n, ")
{
#(map-binds #{connect(#.provided ,#.required );
#} (filter (negate bind-port?) (ast:binds model))) }
