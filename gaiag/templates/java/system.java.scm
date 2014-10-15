class #.model  {
#(map (init-instance #{
    #component  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    #interface  #name;
#}) ((compose .elements .ports) model))
public #.model () {
#(map (init-instance #{
    #name  = new #component();
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
    #port  = #instance;
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
    Interface.connect(#provided , #required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))};
}
