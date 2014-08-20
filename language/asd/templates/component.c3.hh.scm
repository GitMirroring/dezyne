##ifndef #.COMPONENT _COMPONENT_HH
##define #.COMPONENT _COMPONENT_HH

#(map-ports
#{
##include "#.interface Interface-c3.hh"
#} (ast:ports model))
struct #.model
{
#(map-ports
#{
  #.interface Interface #.port ;
#} (ast:ports model))
  #.model ();
#(map-ports #{#(map-port-events #{void #.event ();
#} port (filter ast:in? (ast:events port))) #} (filter ast:provides? (ast:ports model)))#
(map-ports #{#(map-port-events #{void #.event ();
#} port (filter ast:out? (ast:events port))) #} (filter ast:requires? (ast:ports model)))};

##endif
