import dzn
import runtime

def connect (provided, required):
    provided.outport = required.outport
    required.inport = provided.inport

class #.scope_model (runtime.Component):
    def __init__ (self, loc, name='', parent=None):
        runtime.Component.__init__ (self, loc, name, parent)
#(map (init-instance #{
        self.#name  = dzn.#((om:scope-name) component)  (loc, name='#name ', parent=self)
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
        loc = loc.clone ()#
    (map (init-bind model #{.set (self.#instance)#}) (injected-bindings model))
#})#
(map (init-instance #{
        self.#name  = dzn.#((om:scope-name) component)  (loc, name='#name ', parent=self)
#}) (non-injected-instances model))#
(map (init-bind model #{
        self.#port  = self.#instance
#}) (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
# (map (connect-ports model #{
        connect (self.#provided , self.#required)
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model)))
