dezyne.#.model  = function(rt, meta) {
  rt.top = rt.top || this;
  rt.components = (rt.components || []).concat ([this]);
  this.rt = rt;
  this.meta = meta;
#(map (init-instance #{
    this.#name  = new dezyne.#component (rt, {parent: this, name: '#name '});
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
    this.#port  = this.#instance;
#}) (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))#
'()this.children = [#((->join ", ") (map (init-instance #{ this.#name #}) ((compose .elements .instances) model)))];
# (map (connect-ports model #{
    dezyne.connect(this.#provided , this.#required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
};
