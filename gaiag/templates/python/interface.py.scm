class #.interface  ():
#(->string (map declare-enum (gom:interface-enums model)))#'(
)     def __init__ (self):
        class Ins ():
#(map (declare-io model #{
            #name  = None
#}) (filter gom:in? ((compose .elements .events) model)))#
(if (null? (filter gom:in? ((compose .elements .events) model)))
    "            pass")#'(
)         self.ins = Ins ()
        class Outs ():
#(map (declare-io model #{
            #name  = None
#}) (filter gom:out? ((compose .elements .events) model)))#
(if (null? (filter gom:out? ((compose .elements .events) model)))
    "            pass\n")#'(
)         self.outs = Outs ()
