#(javascript:preamble model)
#(javascript:namespace model).#.interface  = function #.interface (meta) {#
(->string (map (declare-enum model) (append (om:interface-enums model) (om:enums))))
  this.in = {
#((->join ",\n") (map (declare-io model #{
    #name  : null#})
 (filter om:in? ((compose .elements .events) model)))
)
  };
  this.out = {
#((->join ",\n") (map (declare-io model #{
    #name  : null#})
 (filter om:out? ((compose .elements .events) model))))
  };
  this.meta = meta;
};

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
}
