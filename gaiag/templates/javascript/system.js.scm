#(javascript:preamble model)#
(map (include-component #{
dzn.extend (dzn_require (__dirname + '/#component '));
#}) (delete-duplicates ((compose .elements .instances) model)))#
(map (include-interface #{
dzn.extend (dzn_require (__dirname + '/#interface '));
#}) (delete-duplicates (om:ports model) (lambda (x y) (om:equal? (.type x) (.type y)))))
#(javascript:namespace model).#.model  = function (locator, meta) {
  this._dzn = {};
  this._dzn.locator = locator;
  this._dzn.rt = locator.get(new dzn.runtime());
  this._dzn.rt.top = this._dzn.rt.top || this;
  this._dzn.rt.components = (this._dzn.rt.components || []).concat ([this]);
  this._dzn.meta = meta;
  this._dzn.meta.ports = [#((->join ",") (map (lambda (s) (list "'" (.name s) "'")) ((compose .elements .ports) model)))];
  this._dzn.meta.children = [#((->join ",") (map (init-instance model #{'#name '#}) ((compose .elements .instances) model)))];
#(map (init-instance model #{
    this.#name  = new dzn.#((om:scope-name '.) component)(locator, {parent: this, name: '#name '});
#}) (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{
   this._dzn.locator = locator.clone()#
    (map (init-bind model #{.set(this.#instance)#}) (injected-bindings model));
#})#
(map (init-instance model #{
    this.#name  = new dzn.#((om:scope-name) component)(this._dzn.locator, {parent: this, name: '#name '});
#}) (non-injected-instances model))#
(map (init-bind model #{
    this.#port  = this.#instance;
#}) (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))
#(map (connect-ports model #{
                               dzn.connect(this.#provided , this.#required);
                                          #}) (filter (negate om:port-bind?) ((compose .elements .bindings) model)))
}

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
}
