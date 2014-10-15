function connect(provided, required) {
  provided.out = required.out;
  required.in = provided.in;
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
};
