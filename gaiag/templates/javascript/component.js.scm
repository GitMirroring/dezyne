dezyne.#.model  = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;#
(->string (map declare-enum (gom:enums (.behaviour model))))
#
    (map (init-member model #{
  this.#name  = #expression;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
  this.#name  = new dezyne.#interface (#(string-if (eq? direction 'requires) #{{provides: {}, requires: {name: '#name ', component: this}}#} #{{provides: {name: '#name ', component: this}, requires: {}}#}));
#}) ((compose .elements .ports) model))
  if (this.rt.event_map) {
#(map
    (lambda (port)
      (map (define-on model port #{
      this.#port .#direction .#event  = function() {console.error('#port .#event '); };
#}) (gom:events port))) (gom:ports model))
  }
#(map
   (lambda (port)
     (map (define-on model port #{
  this.#port .#direction .#event  = function(#arguments) {
  #(string-if (not (eq? type 'void)) #{return #})runtime.call_#direction(this, function() {
  #statement #(string-if (not (eq? type 'void))
#{ return this.reply_#reply-type _#reply-name;
#}) }.bind(this), [this.#port , '#event '#(string-if (not (eq? type 'void))#{, this.#port .#reply-name _to_string#})]);
}.bind(this);
#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))
  if (this.rt.event_map) {
#(map
    (lambda (port)
      (map (define-on model port #{
          this.rt.event_map['#port .#event '] = this.#port .#direction .#event;
#}) (gom:events port))) (gom:ports model))
}
#
(map (define-function model #{
   this.#name  = function (#parameters) {
#statements }.bind(this);
#}) (gom:functions model))
};
