interface.#.interface = function() {
#(->string (map declare-enum (gom:interface-enums model)))
  this.ins = {
#((->join ",\n") (map (declare-io #{
    #name  : null#})
 (filter gom:in? ((compose .elements .events) model)))
)
  }
    this.outs = {
#((->join ",\n") (map (declare-io #{
    #name  : null#})
 (filter gom:out? ((compose .elements .events) model))))
  }
}
