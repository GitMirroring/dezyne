class #.scope_model  extends SystemComponent {
#(map (init-instance #{
    #((om:scope-name) component)  #name;
#}) ((compose .elements .instances) model))#
(map (init-port #{
    #((om:scope-join) interface)  #name;
#}) ((compose .elements .ports) model))

  public #.scope_model(Locator locator) {this(locator, "");};

  public #.scope_model(Locator locator, String name) {this(locator, name, null);};

  public #.scope_model(Locator locator, String name, SystemComponent parent) {
  super(locator, name, parent);
#(map (init-instance #{
    #name  = new #((om:scope-name) component)(locator, "#name ", this);
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
    locator = locator.clone()#
    (map (init-bind model #{.set(#instance);#}) (injected-bindings model))
#})#
(map (init-instance #{
    #name  = new #((om:scope-name) component)(locator, "#name ", this);
#}) (non-injected-instances model))#
(map (init-bind model #{
    #port  = #instance;
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
# (map (connect-ports model #{
    Interface.connect(#provided , #required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))};
}
