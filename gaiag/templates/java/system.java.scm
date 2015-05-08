class #.model  extends SystemComponent {
#(map (init-instance #{
    #component  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    #interface  #name;
#}) ((compose .elements .ports) model))

  public #.model(Locator locator) {this(locator, "");};

  public #.model(Locator locator, String name) {this(locator, name, null);};

  public #.model(Locator locator, String name, SystemComponent parent) {
  super(locator, name, parent);
#(map (init-instance #{
    #name  = new #component(locator, "#name ", this);
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
    locator = locator.clone()#
    (map (init-bind model #{.set(#instance);#}) (injected-bindings model))
#})#
(map (init-instance #{
    #name  = new #component(locator, "#name ", this);
#}) (non-injected-instances model))#
(map (init-bind model #{
    #port  = #instance;
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
# (map (connect-ports model #{
    Interface.connect(#provided , #required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))};
}
