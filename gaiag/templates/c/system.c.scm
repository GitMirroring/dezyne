##include "#.model .h"

##define CONNECT(provided, required)\
  {\
	  provided.out = required.out;\
	  required.in = provided.in;\
  }

void #.model _init(#.model *self, locator* dezyne_locator) {
#((->join ";\n")
    (append (map (lambda (binding) (list (injected-instance-name binding) "(dezyne_locator)"))
                 (injected-bindings model))
            (list (if (pair? (injected-bindings model))
                      (list "dezyne_local_locator(dezyne_locator.clone()" (map (lambda (binding) (list ".set(" (binding-name model (injected-binding binding)) ")"))  (injected-bindings model)) ")")))
            (map (init-instance #{ #component _init (&self->#name , #(if (pair? (injected-bindings model)) "dezyne_local_locator" "dezyne_locator"))#})
                 (non-injected-instances model))
            (map (init-bind model #{ self->#port  = self->#instance; #})
                 (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))
 # (map (connect-ports model #{
    CONNECT(self->#provided , self->#required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }
