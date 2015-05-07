import dezyne
import runtime

def connect (provided, required):
    provided.outport = required.outport
    required.inport = provided.inport

class #.model (runtime.Component):
    def __init__ (self, loc, name='', parent=None):
        runtime.Component.__init__ (self, loc, name, parent)
#(map (init-instance #{
        self.#name  = dezyne.#component  (loc, name='#name ', parent=self)
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
        loc = loc.clone ()#
    (map (init-bind model #{.set (self.#instance)#}) (injected-bindings model))
#})#
(map (init-instance #{
        self.#name  = dezyne.#component  (loc, name='#name ', parent=self)
#}) (non-injected-instances model))#
(map (init-bind model #{
        self.#port  = self.#instance
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
# (map (connect-ports model #{
        connect (self.#provided , self.#required)
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
