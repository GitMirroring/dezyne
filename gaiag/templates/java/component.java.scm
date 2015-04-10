class #.model  extends Component {#
(->string (map declare-enum (gom:enums (.behaviour model))))#
(->string (map declare-integer (gom:integers (.behaviour model))))
#
    (map (init-member model #{#'()
  #type  #name;#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{#'()
  #interface  #name;#}) ((compose .elements .ports) model))

  public #.model(Runtime runtime) {this(runtime, "");};

  public #.model(Runtime runtime, String name) {this(runtime, name, null);};

  public #.model(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);#
(map (init-member model #{#'()
    #name  = #expression;#}) (gom:variables model))#
    (map (init-port #{#'()
    #name  = new #interface();#}) ((compose .elements .ports) model))#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  #port .get#(symbol-capitalize direction)().#event  = new #(action-type return-type)() {public #return-type  action() {Runtime.call#(symbol-capitalize direction)(#.model .this, new #(action-type return-type) () {public #return-type  action() {#(string-if (not (eq? return-type 'void)) #{return #})#port _#event();}}, new Meta(Alarm.this.#port , "#event"));};};
   #}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))
  };#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  public #return-type  #port _#event () {
  #statement #(if (not (eq? type 'void))
(list "return reply_" reply-type "_" reply-name ";\n")) };
#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
   public #return-type  #name  (#parameters) {
#statements };
#}) (gom:functions model))
}
