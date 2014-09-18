##include "component-#.model -c3.hh"

namespace component
{
#.model ::#.model ()
: # (string-if (.behaviour model) #{ # (map-variables
#{ #.variable (#.scope- #.value )#} ((compose .elements .variables .behaviour) model) "\n, ")
  #(if (null-is-#f (.elements (.variables (.behaviour model)))) ", " "") #}) #(map-ports
          #{#.port-name ()#} ((compose .elements .ports) model) "\n, ")
  {
#(map-ports #{#(map-port-events #{#.port-name .in.#.event-name  = asd::bind(&#.model ::#.event-name , this);
#} port (filter gom:in? (gom:events port))) #} (filter gom:provides? ((compose .elements .ports) model)))#
(map-ports #{#(map-port-events #{#.port-name .out.#.event-name  = asd::bind(&#.model ::#.event-name , this);
#} port (filter gom:out? (gom:events port))) #} (filter gom:requires? ((compose .elements .ports) model))) }

#(map-ports
#{
#(map-port-events
#{
    #.return-interface-type  #.model ::#.event-name ()
    {
      std::cout << "#.component .#.event-name" << std::endl;
      #.statement-
      #(if (not (eq? (.name .type-) 'void)) (->string (list "return reply_" .reply-type ";\n")))
    }
#}
    port (filter (gom:dir-matches? port) (gom:events port)))
#} ((compose .elements .ports) model))

#(string-if (.behaviour model)
#{
#(map-functions
  #{  #.return-type  #.model ::#.function (#.parameters- )
  {
    #.statements
  }
#}
((compose .elements .functions .behaviour) model))
#})

}
