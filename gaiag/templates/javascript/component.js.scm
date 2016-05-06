#(javascript:preamble model)#
(map (include-interface #{
dzn.extend (dzn, dzn_require (__dirname + '/#interface '));
#}) (delete-duplicates (om:ports model) (lambda (x y) (eq? (.type x) (.type y)))))
#(javascript:namespace model).#.model  = function (locator, meta) {
  this.locator = locator;
  this.rt = locator.get(new dzn.runtime());
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
  this.meta.ports = [#((->join ",") (map (lambda (s) (list "'" (.name s) "'")) ((compose .elements .ports) model)))];
  this.meta.children = [];
  this.flushes = true;#
  (->string (map (declare-enum model) (append (om:enums (.behaviour model)) (om:enums))))
  #(map (init-member model #{
  #(string-if (eq? expression *unspecified*) "" #{this.#name  = #expression ;
#})#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
  this.#name  = new dzn.#((om:scope-join #f '.) interface)({provides: {name: '#name ', component: this}, requires: {}});
#}) (filter om:provides? ((compose .elements .ports) model)))#
    (map (init-port #{#(string-if injected?
#{
  this.#name  = locator.get(new dzn.#((om:scope-join #f '.) interface)());
#}
#{
  this.#name  = new dzn.#((om:scope-join #f '.) interface)({provides: {}, requires: {name: '#name ', component: this}});
#})#}) (filter om:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{
  this.#port .#direction .#event  = function(#arguments) {
  #statement #(string-if (not (eq? type 'void))
#{ return this.reply_#((om:scope-join #f) reply-scope)_#reply-name;
#}) };
#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))
#
(map (define-function model #{
   this.#name  = function (#formals) {
#statements }.bind(this);
#}) (om:functions model))
  this.rt.bind(this);
};

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
}
