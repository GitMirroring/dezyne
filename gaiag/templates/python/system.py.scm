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
# (map (connect-ports model #{
        connect (self.#provided , self.#required)
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
