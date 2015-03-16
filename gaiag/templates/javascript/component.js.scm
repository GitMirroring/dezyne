dezyne.#.model  = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;#
(->string (map declare-enum (gom:enums (.behaviour model))))
#
    (map (init-member model #{
  this.#name  = #expression;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
  this.#name  = new dezyne.#interface ({provides: this, requires: this});
#}) ((compose .elements .ports) model))
#(map
   (lambda (port)
     (map (define-on model port #{
  this.#port .#direction .#event  = function(#arguments) {
  #(string-if (not (eq? type 'void)) #{return #})runtime.call_#direction(this, function() {
  #statement #(string-if (not (eq? type 'void))
#{ return this.reply_#reply-type _#reply-name;
#}) }.bind(this), [this.#port , '#port ', '#event ']);
}.bind(this);
#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
   this.#name  = function (#parameters) {
#statements }.bind(this);
#}) (gom:functions model))
};
