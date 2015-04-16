import runtime

class #.interface :
#(->string (map declare-enum (gom:interface-enums model)))#'(
)#(->string (map enum-to-string (gom:interface-enums model)))#'(
)     def __init__ (self, provides=runtime.Port (), requires=runtime.Port ()):
        class In (runtime.Port):
            def __init__ (self, port):
                runtime.Port.__init__ (self, port.name, port.component)
#(map (declare-io model #{
                self.#name  = None
#}) (filter gom:in? ((compose .elements .events) model)))#'(
)         self.inport = In (provides)
        class Out (runtime.Port):
            def __init__ (self, port):
                runtime.Port.__init__ (self, port.name, port.component)
#(map (declare-io model #{
                self.#name  = None
#}) (filter gom:out? ((compose .elements .events) model)))#'(
)         self.outport = Out (requires)
