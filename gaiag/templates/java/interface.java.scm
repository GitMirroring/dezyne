class #.interface  extends Interface<#.interface .In, #.interface .Out> {#
(->string (map (declare-enum model) (gom:interface-enums model)))
  class In extends Interface.In {
#((->join "\n") (map (declare-io model #{
    #(action-type return-type parameter-types)  #name ;#})
 (filter gom:in? ((compose .elements .events) model)))
)
  }
    class Out extends Interface.Out {
#((->join "\n") (map (declare-io model #{
    #(action-type return-type parameter-types)  #name;#})
 (filter gom:out? ((compose .elements .events) model))))
  }
  public #.interface() {
    in = new In();
    out = new Out();
  }
}
