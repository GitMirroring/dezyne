class #.model  {
#(map (init-instance #{
    #component  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    #interface  #name;
#}) ((compose .elements .ports) model))

  public #.model(Runtime runtime) {this(runtime, "");};

  public #.model(Runtime runtime, String name) {this(runtime, name, null);};

  public #.model(Runtime runtime, String name, System parent) {
  super(runtime, name, parent);
#(map (init-instance #{
    #name  = new #component(runtime);
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
    #port  = #instance;
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
    Interface.connect(#provided , #required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))};
}
