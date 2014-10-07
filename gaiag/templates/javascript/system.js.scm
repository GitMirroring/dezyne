function connect(provided, required) {
  provided.outs = required.outs;
  required.ins = provided.ins;
}

component.#.model  = function() {
#(map (init-instance #{
    this.#name  = new component.#component ();
#}) ((compose .elements .instances) model))#
(map (init-bind model #{
    this.#port  = this.#instance;
#}) (filter bind-port? ((compose .elements .bindings) model)))
# (map (connect-ports model #{
    connect(this.#provided , this.#required);
#}) (filter (negate bind-port?) ((compose .elements .bindings) model)))
}
