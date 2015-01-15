##include "#.model .h"

##define CONNECT(provided, required)\
  {\
	provided.out = required.out;\
	required.in = provided.in;\
  }

void #.model _init(#.model  *self, locator* dezyne_locator) {
#((->join ";\n")
    (append 
            (list (if (pair? (injected-bindings model))
                      (list "locator* local_locator = locator_clone(dezyne_locator);\n" (map (lambda (binding) (list "locator_set(local_locator, \"" (injected-instance-interface model binding) "\", &self->" (binding-name model (injected-binding binding)) ")")) (injected-bindings model)))))
            (map (init-instance #{ #component _init(&self->#name , #(if (pair? (injected-bindings model)) "local_locator" "dezyne_locator"))#})
                 (.elements (.instances model)))
            (map (lambda (binding) 
                   (if (injected-binding? binding) 
                       (list "self->" (injected-instance-name binding) "." (injected-instance-port binding) ".in.self = &self->" (injected-instance-name binding))
                       (append
                        (if (.instance (.left binding))
                            (list "self->" (.instance (.left binding)) "." (.port (.left binding)) ".in.self = " (if (.instance (.right binding)) (list "&self->" (.instance (.right binding)) ";\n") "self"))
                            '())
                        (if (.instance (.right binding))
                            (list "self->" (.instance (.right binding)) "." (.port (.right binding)) ".in.self = " (if (.instance (.left binding)) (list "&self->" (.instance (.left binding))) "self"))))))
                 (.elements (.bindings model)))
            (map (init-bind model #{ self->#port  = self->#instance; #})
                 (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))
 # (map (connect-ports model #{
    CONNECT(self->#provided , self->#required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }
