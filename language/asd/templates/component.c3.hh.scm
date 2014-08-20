##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map-ports
#{
##include "interface-#.interface -c3.hh"
#} (ast:ports model))
namespace component
{
struct #.model
{
#(map-ports
#{
  interface::#.interface  #.port ;
#} (ast:ports model))
  #.model ();
#(map-ports #{#(map-port-events #{void #.event ();
#} port (filter ast:in? (ast:events port))) #} (filter ast:provides? (ast:ports model)))#
(map-ports #{#(map-port-events #{void #.event ();
#} port (filter ast:out? (ast:events port))) #} (filter ast:requires? (ast:ports model)))};
}

##endif
