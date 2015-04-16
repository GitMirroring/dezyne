import dezyne
import runtime

def connect (provided, required):
    provided.outport = required.outport
    required.inport = provided.inport

class #.model (runtime.Component):
    def __init__ (self, rt, name='', parent=None):
        runtime.Component.__init__ (self, rt, name, parent)
#(map (init-instance #{
        self.#name  = dezyne.#component  (self.rt, name='#name ', parent=self)
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
        self.#port  = self.#instance
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
        connect (self.#provided , self.#required)
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
