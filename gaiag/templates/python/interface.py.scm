import runtime

class #.scope_model :
#(->string (map (declare-enum model) (append (om:interface-enums model) (om:enums))))#'(
)#(->string (map (enum-to-string model) (append (om:interface-enums model) (om:enums))))#'(
)     def __init__ (self, provides=runtime.Port (), requires=runtime.Port ()):
        class In (runtime.Port):
            def __init__ (self, port):
                runtime.Port.__init__ (self, port.name, port.component)
#(map (declare-io model #{
                self.#name  = None
#}) (filter om:in? ((compose .elements .events) model)))#'(
)         self.inport = In (provides)
        class Out (runtime.Port):
            def __init__ (self, port):
                runtime.Port.__init__ (self, port.name, port.component)
#(map (declare-io model #{
                self.#name  = None
#}) (filter om:out? ((compose .elements .events) model)))#'(
)         self.outport = Out (requires)
