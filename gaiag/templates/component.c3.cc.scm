##include "component-#.model -c3.hh"

namespace component
{
#.model ::#.model ()
:# (comma-join
    (map
     (lambda (variable)
       (let* ((name (.name variable))
              (type (.type variable))
              (enum? (gom:enum model (.name type)))
              (scope (if enum? (->string (list (.name type) "::"))))
              (value (expression->string model (.expression variable))))
         (->string (list name "(" scope value ")\n"))))
    (gom:variables model)))
# (if (null? (gom:variables model)) "" ", ") #(map-ports
          #{#.port-name ()#} ((compose .elements .ports) model) "\n, ")
  {
#(map-ports #{#(map-port-events #{#.port-name .in.#.event-name  = asd::bind(&#.model ::#.port-name _#.event-name , this);
#} port (filter gom:in? (gom:events port))) #} (filter gom:provides? ((compose .elements .ports) model)))#
(map-ports #{#(map-port-events #{#.port-name .out.#.event-name  = asd::bind(&#.model ::#.port-name _#.event-name , this);
#} port (filter gom:out? (gom:events port))) #} (filter gom:requires? ((compose .elements .ports) model))) }

#(map-ports
#{
#(map-port-events
#{
    #.return-interface-type  #.model ::#.port-name _#.event-name ()
    {
      std::cout << "#.component .#.port-name _#.event-name" << std::endl;
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
