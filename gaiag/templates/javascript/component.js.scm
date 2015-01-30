dezyne.#.model  = function() {#
(->string (map declare-enum (gom:enums (.behaviour model))))
#
    (map (init-member model #{
  this.#name  = #expression;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
  this.#name  = new dezyne.#interface ();
#}) ((compose .elements .ports) model))
#(map
   (lambda (port)
     (map (define-on model port #{
  this.#port .#direction .#event  = function(#arguments) {
  console.log('#.model .#port _#event ');
  #statement #(if (not (eq? type 'void))
(list "return this.reply_" reply-type "_" reply-name ";\n")) }.bind(this);
#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
   this.#name  = function (#parameters) {
#statements }.bind(this);
#}) (gom:functions model))
};
