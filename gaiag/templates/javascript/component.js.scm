function #.model(locator, meta) {
  this.locator = locator;
  this.rt = locator.get(dezyne.runtime);
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;#
(->string (map (declare-enum model) (append (gom:enums (.behaviour model)) (gom:enums))))
#
    (map (init-member model #{
  #(string-if (eq? expression *unspecified*) "" #{this.#name  = #expression ;
#})#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
  this.#name  = new dezyne.#interface({provides: {name: '#name ', component: this}, requires: {}});
#}) (filter gom:provides? ((compose .elements .ports) model)))#
    (map (init-port #{
#(string-if injected?
#{
    this.#name  = locator.get(dezyne.#interface);
#}
#{
    this.#name  = new dezyne.#interface({provides: {}, requires: {name: '#name ', component: this}});
#})
#}) (filter gom:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{
  this.#port .#direction .#event  = function(#arguments) {
  #(string-if (not (eq? type 'void)) #{return #})this.rt.call_#direction(this, function() {
  #statement #(string-if (not (eq? type 'void))
#{ return this.reply_#(*scope* reply-scope)_#reply-name;
#}) }.bind(this), [this.#port , '#event '#(string-if (not (eq? type 'void))#{, this.#port .#reply-name _to_string#})]);
}.bind(this);
#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))
#
(map (define-function model #{
   this.#name  = function (#parameters) {
#statements }.bind(this);
#}) (gom:functions model))
};

dezyne.#.model  = #.model;
