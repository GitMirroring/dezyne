#(map-instances
#{
##include "component-#.type -c3.hh"
#} (gom:instances model))

#(map-ports
#{
##include "interface-#.interface -c3.hh"
#} ((compose .elements .ports) model))
namespace component
{
struct #.model
{
#(map-instances
#{
   #.type  #.instance ;
#} (gom:instances model))
#(map-ports
#{
  interface::#.interface & #.port-name ;
#} ((compose .elements .ports) model))
  #.model ();
};
}
