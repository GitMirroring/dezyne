##ifndef DEZYNE_#.COMPONENT _H
##define DEZYNE_#.COMPONENT _H

#(map (include-component #{
##include "#component .h"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "#interface .h"
#}) (gom:ports model))

##include "locator.h"

typedef struct {
    dzn_meta_t dzn_meta;
#(map (lambda (binding) (list (.component (gom:instance model (injected-instance-name binding))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model)) #
(if (pair? (injected-bindings model)) (list "locator local_locator;\n")) #
(map (init-instance #{
  #component  #name;
#}) (non-injected-instances model))
#(map (init-port #{
  #interface * #name;
#}) ((compose .elements .ports) model))
} #.model;

void #.model _init(#.model *self, locator* dezyne_locator, dzn_meta_t* dzn_meta);

##endif // DEZYNE_#.COMPONENT _H
