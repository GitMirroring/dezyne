#(javascript:preamble model)#
(map (include-component #{
dzn.extend (dzn_require (__dirname + '/#component '));
#}) (delete-duplicates ((compose .elements .instances) model)))#
(map (include-interface #{
dzn.extend (dzn_require (__dirname + '/#interface '));
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))
#(javascript:namespace model).#.model  = function (locator, meta) {
  this.locator = locator;
  this.rt = locator.get(new dzn.runtime());
  this.rt.top = this.rt.top || this;
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
#(map (init-instance #{
    this.#name  = new dzn.#((om:scope-name '.) component)(locator, {parent: this, name: '#name '});
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
   this.locator = locator.clone()#
    (map (init-bind model #{.set(this.#instance)#}) (injected-bindings model));
#})#
(map (init-instance #{
    this.#name  = new dzn.#((om:scope-name) component)(this.locator, {parent: this, name: '#name '});
#}) (non-injected-instances model))#
(map (init-bind model #{
    this.#port  = this.#instance;
#}) (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))#
'()this.children = [#((->join ", ") (map (init-instance #{ this.#name #}) ((compose .elements .instances) model)))];
# (map (connect-ports model #{
    dzn.connect(this.#provided , this.#required);
#}) (filter (negate om:port-bind?) ((compose .elements .bindings) model)))
};

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
}
