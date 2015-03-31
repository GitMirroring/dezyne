##ifndef DEZYNE_#.COMPONENT _H
##define DEZYNE_#.COMPONENT _H

#(map (include-interface #{
##include "#interface .h"
#}) (gom:ports model))

##include "runtime.h"
##include "locator.h"


typedef struct {
    dzn_meta_t dzn_meta;
    runtime_sub dzn_sub;
    #(map (init-member model #{
#type  #name;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
#interface  #name _;
#interface * #name;
#}) ((compose .elements .ports) model))} #.model;

void #.model _init(#.model * self, locator* dezyne_locator, dzn_meta_t* dzn_meta);

##endif // DEZYNE_#.COMPONENT _H
