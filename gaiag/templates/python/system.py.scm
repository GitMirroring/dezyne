import dezyne

def connect (provided, required):
    provided.outs = required.outs
    required.ins = provided.ins

class #.model :
    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
#(map (init-instance #{
        self.#name  = dezyne.#component  (self.rt, parent=self, name='#name ')
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
        self.#port  = self.#instance
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
        connect (self.#provided , self.#required)
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
