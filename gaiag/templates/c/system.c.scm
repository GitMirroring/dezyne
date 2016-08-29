##include "#.scope_model .h"

##include <string.h>

##if DZN_TRACING

void #.scope_model _init(#.scope_model  *self, locator* dezyne_locator, dzn_meta_t* dzn_meta) {
   memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));#
(map (init-instance model #{
  dzn_meta_t dzn_m_#name  = {"#name ", &self->dzn_meta};
  #((om:scope-name) component) _init(&self->#name , dezyne_locator
, &dzn_m_#name
);#})
  (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{#'()
   dezyne_locator = locator_clone(dezyne_locator);#})#
    (map (init-bind model #{#'()
       self->#instance ->meta.requires.port = "#instance-port ";
       locator_set(dezyne_locator, "#((om:scope-name) interface) ", &self->#instance _);#}) (injected-bindings model))#
(map (init-instance model #{#'()
  dzn_meta_t dzn_m_#name  = {"#name ", &self->dzn_meta};
  #((om:scope-name) component) _init(&self->#name , dezyne_locator, &dzn_m_#name);#})
   (non-injected-instances model))#
(map (init-bind model #{#'()
  self->#port  = self->#instance; #})
    (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
 # (map (connect-ports model #{
    DZN_CONNECT(self->#provided , self->#required );
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model))) }

##else // !DZN_TRACING

void #.scope_model _init(#.scope_model  *self, locator* dezyne_locator) {#
(map (init-instance model #{
  #((om:scope-name) component) _init(&self->#name , dezyne_locator);#})
  (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{#'()
   dezyne_locator = locator_clone(dezyne_locator);#})#
    (map (init-bind model #{#'()
    locator_set(dezyne_locator, "#((om:scope-name) interface) ", &self->#instance _);#}) (injected-bindings model))#
(map (init-instance model #{#'()
  #((om:scope-name) component) _init(&self->#name , dezyne_locator);#})
   (non-injected-instances model))#
(map (init-bind model #{#'()
  self->#port  = self->#instance; #})
    (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
 # (map (connect-ports model #{
    DZN_CONNECT(self->#provided , self->#required );
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model))) }

##endif // !DZN_TRACING
