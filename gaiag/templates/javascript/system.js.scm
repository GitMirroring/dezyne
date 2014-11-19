dezyne.#.model  = function() {
#(map (init-instance #{
    this.#name  = new dezyne.#component ();
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
    this.#port  = this.#instance;
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
    dezyne.connect(this.#provided , this.#required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
};
