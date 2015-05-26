function #.model(locator, meta) {
  this.locator = locator;
  this.rt = locator.get(dezyne.runtime);
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;#
(->string (map (declare-enum model) (append (om:enums (.behaviour model)) (om:enums))))
#
    (map (init-member model #{
  #(string-if (eq? expression *unspecified*) "" #{this.#name  = #expression ;
#})#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
  this.#name  = new dezyne.#interface({provides: {name: '#name ', component: this}, requires: {}});
#}) (filter om:provides? ((compose .elements .ports) model)))#
    (map (init-port #{
#(string-if injected?
#{
    this.#name  = locator.get(dezyne.#interface);
#}
#{
    this.#name  = new dezyne.#interface({provides: {}, requires: {name: '#name ', component: this}});
#})
#}) (filter om:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{
  this.#port .#direction .#event  = function(#arguments) {
  #(string-if (not (eq? type 'void)) #{return #})this.rt.call_#direction(this, function() {
  #statement #(string-if (not (eq? type 'void))
#{ return this.reply_#(*scope* reply-scope)_#reply-name;
#}) }.bind(this), [this.#port , '#event '#(string-if (not (eq? type 'void))#{, this.#port .#reply-name _to_string#})]);
}.bind(this);
#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))
#
(map (define-function model #{
   this.#name  = function (#formals) {
#statements }.bind(this);
#}) (om:functions model))
};

dezyne.#.model  = #.model;
