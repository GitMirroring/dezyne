class #.interface  extends Interface<#.interface .In, #.interface .Out> {#
(->string (map (declare-enum model) (om:interface-enums model)))
  class In extends Interface.In {
#((->join "\n") (map (declare-io model #{
    #(action-type return-type formal-types)  #name ;#})
 (filter om:in? ((compose .elements .events) model)))
)
  }
    class Out extends Interface.Out {
#((->join "\n") (map (declare-io model #{
    #(action-type return-type formal-types)  #name;#})
 (filter om:out? ((compose .elements .events) model))))
  }
  public #.interface() {
    in = new In();
    out = new Out();
  }
}
