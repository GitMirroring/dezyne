##include "#.model .h"

##include <string.h>

##define CONNECT(provided, required)\
  {\
	provided->out = required->out;\
	required->in = provided->in;\
  }

void #.model _init(#.model  *self, locator* dezyne_locator, meta* m) {
#((->join ";\n")
    (append
            (list (if (pair? (injected-bindings model))
                      (list "locator* local_locator = locator_clone(dezyne_locator);\n" (map (lambda (binding) (list "locator_set(local_locator, \"" (injected-instance-interface model binding) "\", &self->" (binding-name model (injected-binding binding)) "_)")) (injected-bindings model)))))
            (list "memcpy(&self->m, m, sizeof(meta))")
            (map (init-instance #{ meta m_#name  = {"#name ", self};
  #component _init(&self->#name , #(string-if (pair? (injected-bindings model)) #{local_locator#} #{dezyne_locator#}), &m_#name)#})
                 (.elements (.instances model)))
            (map (init-bind model #{ self->#port  = self->#instance #})
             (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))));
 # (map (connect-ports model #{
    CONNECT(self->#provided , self->#required );
#}) (filter (negate bind-port?) ((compose .elements .bindings) model))) }
