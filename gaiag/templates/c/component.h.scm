##ifndef DEZYNE_#.COMPONENT _H
##define DEZYNE_#.COMPONENT _H

#(map (include-interface #{
##include "#interface .h"
#}) (gom:ports model))

##include "runtime.h"
##include "locator.h"


typedef struct {
    runtime* rt;
    #(map (init-member model #{
#type  #name;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
#interface  #name _;
#interface * #name;
#}) ((compose .elements .ports) model))} #.model;

void #.model _init(#.model * self, locator* dezyne_locator);

#(map (define-function model #{
  #return-type  #name (#parameters);
#}) (gom:functions model))

##endif // DEZYNE_#.COMPONENT _H
