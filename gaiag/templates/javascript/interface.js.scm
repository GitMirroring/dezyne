function #.interface(meta) {#
(->string (map (declare-enum model) (append (gom:interface-enums model) (gom:enums))))
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

dezyne.#.interface  = #.interface;
