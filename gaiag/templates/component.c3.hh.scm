##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map-ports
#{
##include "interface-#.interface-name -c3.hh"
#} ((compose .elements .ports) model))
namespace component
{
struct #.model
{
    #(->string (map declare-enum (gom:enums (.behaviour model))))
    #(->string (map declare-integer (gom:integers (.behaviour model))))

# (map
   (lambda (variable)
       (let* ((name (.name variable))
              (type (.type variable))
              (enum? (gom:enum model (.name type)))
              (c++-type (if enum?
                           (->string (list (.name type) "::type"))
                           (.name type))))
         (->string (list c++-type " " name ";\n"))))
   (gom:variables model))

  #(delete-duplicates (map (compose declare-replies c++:import .type) ((compose .elements .ports) model)))


#(map-ports
#{
  interface::#.interface-name  #.port-name ;
#} ((compose .elements .ports) model))
  #.model ();
#(map-ports #{#(map-port-events #{#.return-interface-type  #.port-name _#.event-name ();
#} port (filter gom:in? (gom:events port))) #} (filter gom:provides? ((compose .elements .ports) model)))#
(map-ports #{#(map-port-events #{void #.port-name _#.event-name ();
#} port (filter gom:out? (gom:events port))) #} (filter gom:requires? ((compose .elements .ports) model)))
#(string-if (.behaviour model)
#{
#(map-functions
#{  #.return-type  #.function (#.parameters- );
#}
((compose .elements .functions .behaviour) model))
#})
};
}
##endif
