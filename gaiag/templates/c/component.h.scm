##ifndef DEZYNE_#.COMPONENT _H
##define DEZYNE_#.COMPONENT _H

#(map (include-interface #{
##include "#interface .h"
#}) (gom:ports model))

##include "runtime.h"
##include "locator.h"


typedef struct {
    meta m;
    runtime* rt;
    #(map (init-member model #{
#type  #name;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
#interface  #name _;
#interface * #name;
#}) ((compose .elements .ports) model))} #.model;

void #.model _init(#.model * self, locator* dezyne_locator, meta* m);

##endif // DEZYNE_#.COMPONENT _H
