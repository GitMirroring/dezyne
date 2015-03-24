class #.interface :
#(->string (map declare-enum (gom:interface-enums model)))#'(
)#(->string (map enum-to-string (gom:interface-enums model)))#'(
)     def __init__ (self, provides=('', None), requires=('', None)):
        class Ins:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
#(map (declare-io model #{
                self.#name  = None
#}) (filter gom:in? ((compose .elements .events) model)))#'(
)         self.ins = Ins (*provides)
        class Outs:
            def __init__ (self, name, c):
                self.name = name
                self.self = c
#(map (declare-io model #{
                self.#name  = None
#}) (filter gom:out? ((compose .elements .events) model)))#'(
)         self.outs = Outs (*requires)
