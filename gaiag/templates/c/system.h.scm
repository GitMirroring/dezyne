##ifndef #.COMPONENT _H
##define #.COMPONENT _H

#(map (include-component #{
##include "#component .h"
#}) ((compose .elements .instances) model))

#(map (include-interface #{
##include "#interface .h"
#}) (om:ports model))

##include "locator.h"

typedef struct {
    dzn_meta_t dzn_meta;
#(map (lambda (binding) (list ((c:scope-name) (.component (om:instance model (injected-instance-name binding)))) " "
                              (injected-instance-name binding) ";\n")) (injected-bindings model)) #
(if (pair? (injected-bindings model)) (list "locator local_locator;\n")) #
(map (init-instance #{
  #((om:scope-name) component)  #name;
#}) (non-injected-instances model))
#(map (init-port #{
  #((om:scope-join) interface) * #name;
#}) ((compose .elements .ports) model))
} #.scope_model;

void #.scope_model _init(#.scope_model *self, locator* dezyne_locator, dzn_meta_t* dzn_meta);

##endif // #.COMPONENT _H
