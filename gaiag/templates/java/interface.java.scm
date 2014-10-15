class #.interface  extends Interface<#.interface .In, #.interface .Out> {#
(->string (map declare-enum (gom:interface-enums model)))
  class In implements Interface.In {
#((->join "\n") (map (declare-io #{
    #(action-type return-type)  #name ;#})
 (filter gom:in? ((compose .elements .events) model)))
)
  }
    class Out implements Interface.Out {
#((->join "\n") (map (declare-io #{
    #(action-type return-type)  #name;#})
 (filter gom:out? ((compose .elements .events) model))))
  }
  public #.interface() {
    in = new In();
    out = new Out();
  }
}
