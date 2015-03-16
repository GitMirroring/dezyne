dezyne.#.interface  = function(meta) {#
(->string (map declare-enum (gom:interface-enums model)))
  this.in = {
#((->join ",\n") (map (declare-io model #{
    #name  : null#})
 (filter gom:in? ((compose .elements .events) model)))
)
  };
  this.out = {
#((->join ",\n") (map (declare-io model #{
    #name  : null#})
 (filter gom:out? ((compose .elements .events) model))))
  };
  this.meta = meta;
};
