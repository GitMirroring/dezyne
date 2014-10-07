import component

def connect (provided, required):
    provided.outs = required.outs
    required.ins = provided.ins

class #.model  ():
    def __init__ (self):
#(map (init-instance #{
        self.#name  = component.#component  ()
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
        self.#port  = self.#instance
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map
    (lambda (bind)
      (let* ((left (.left bind))
             (left-port (gom:port model left))
             (right (.right bind))
             (provided-required (if (gom:provides? left-port)
                                    (cons left right)
                                    (cons right left)))
             (provided (binding-name model (car provided-required)))
             (required (binding-name model (cdr provided-required))))
        (->string (list "        connect (self."provided ", self." required ")\n"))))
    (filter (negate bind-port?) ((compose .elements .bindings) model)))
