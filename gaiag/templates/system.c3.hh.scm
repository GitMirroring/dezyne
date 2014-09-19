##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map-instances
#{
##include "component-#.component -c3.hh"
#} ((compose .elements .instances) model))

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
   #.component  #.name ;
#} ((compose .elements .instances) model))
#(map-ports
#{
  interface::#.interface & #.port-name ;
#} ((compose .elements .ports) model))
  #.model ();
};
}
##endif
