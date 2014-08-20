#(map-instances
#{
##include "component-#.type -c3.hh"
#} (ast:instances model))

#(map-ports
#{
##include "interface-#.interface -c3.hh"
#} (ast:ports model))
namespace component
{
struct #.model
{
#(map-instances
#{
   #.type  #.instance ;
#} (ast:instances model))
#(map-ports
#{
  interface::#.interface & #.port ;
#} (ast:ports model))
  #.model ();
};
}
