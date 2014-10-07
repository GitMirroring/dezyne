##ifndef COMPONENT_#.COMPONENT _HH
##define COMPONENT_#.COMPONENT _HH

#(map (include-component #{
##include "component-#component -c3.hh"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "interface-#interface -c3.hh"
#}) (gom:ports model))

namespace component
{
struct #.model
{
#(map (init-instance #{
  #component  #name;
#}) ((compose .elements .instances) model))
#(map (init-port #{
  interface::#interface & #name;
#}) ((compose .elements .ports) model))
  #.model ();
};
}
##endif
