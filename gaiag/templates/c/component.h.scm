##ifndef #.COMPONENT _H
##define #.COMPONENT _H

#(map (include-interface #{
##include "#interface .h"
#}) (om:ports model))

##include "runtime.h"
##include "locator.h"


typedef struct {
    dzn_meta_t dzn_meta;
    runtime_info dzn_info;
    #(map (init-member model #{
#type  #name;
#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
#((c:scope-join) interface)  #name _;
#((c:scope-join) interface) * #name;
#}) ((compose .elements .ports) model))} #.scope_model;

void #.scope_model _init(#.scope_model * self, locator* dezyne_locator, dzn_meta_t* dzn_meta);

##endif // #.COMPONENT _H
