#(map-instances
#{
##include "#.type -c3.hh"
#} (ast:instances model))
#(map-ports
#{
##include "#.interface Interface-c3.hh"
#} (ast:ports model))
struct #.model
{
#(map-instances
#{
   #.type  #.instance ;
#} (ast:instances model))
#(map-ports
#{
  #.interface Interface& #.port ;
#} (ast:ports model))
  #.model ();
};
