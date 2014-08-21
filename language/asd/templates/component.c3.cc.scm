##include "component-#.model -c3.hh"

namespace component
{
#.model ::#.model ()
: # (string-if (ast:behaviour model)
#{
# (map-variables
#{ #.variable (#.value )#} (ast:variables (ast:behaviour model)) "\n, ")
  #}) #(if (null-is-#f (ast:variables (ast:behaviour model))) ", " "") #(map-ports
          #{#.port ()#} (ast:ports model) "\n, ")
  {
#(map-ports #{#(map-port-events #{#.port .in.#.event  = asd::bind(&#.model ::#.event , this);
#} port (filter ast:in? (ast:events port))) #} (filter ast:provides? (ast:ports model)))#
(map-ports #{#(map-port-events #{#.port .out.#.event  = asd::bind(&#.model ::#.event , this);
#} port (filter ast:out? (ast:events port))) #} (filter ast:requires? (ast:ports model))) }

#(string-if (ast:behaviour model)
#{
#(map-ports
#{
#(map-port-events
#{
    void #.model ::#.event ()
    {
      std::cout << "#.component .#.event" << std::endl;
      #.statement
    }
#}
    port (filter (ast:dir-matches? port) (ast:events port)))
#} (ast:ports model))

#(string-if (ast:functions model)
#{
#(map-functions
  #{  #.return-type  #.model ::#.function (#.parameters )
  {
    #.statements
  }
#}
(ast:functions model))
#})
#})

}
