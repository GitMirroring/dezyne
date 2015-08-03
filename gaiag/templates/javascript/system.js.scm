function #.scope_model(locator, meta) {
  this.locator = locator;
  this.rt = locator.get(dezyne.runtime);
  this.rt.top = this.rt.top || this;
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
#(map (init-instance #{
    this.#name  = new dezyne.#((om:scope-name) component)(locator, {parent: this, name: '#name '});
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
   this.locator = locator.clone()#
    (map (init-bind model #{.set(this.#instance)#}) (injected-bindings model))
#})#
(map (init-instance #{
    this.#name  = new dezyne.#((om:scope-name) component)(locator, {parent: this, name: '#name '});
#}) (non-injected-instances model))#
(map (init-bind model #{
    this.#port  = this.#instance;
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))#
'()this.children = [#((->join ", ") (map (init-instance #{ this.#name #}) ((compose .elements .instances) model)))];
# (map (connect-ports model #{
    dezyne.connect(this.#provided , this.#required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
};

dezyne.#.scope_model  = #.scope_model;
