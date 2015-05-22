class #.model  extends Component {#
(->string (map (declare-enum model) (om:enums (.behaviour model))))#
(->string (map declare-integer (om:integers (.behaviour model))))
#
    (map (init-member model #{#'()
  #type  #name;#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{#'()
  #interface  #name;#}) ((compose .elements .ports) model))

  public #.model(Locator locator) {this(locator, "");};

  public #.model(Locator locator, String name) {this(locator, name, null);};

  public #.model(Locator locator, String name, SystemComponent parent) {
    super(locator, name, parent);
    this.flushes = true;#
(map (init-member model #{#'()
    #(string-if (eq? expression (if #f #f)) "" #{#name  = #expression ;#})#}) (om:variables model))#
(map (init-port #{#'()
    #name  = new #interface();
    #name .in.name = "#name ";
    #name .in.self = this;#})
    (filter om:provides? ((compose .elements .ports) model)))#
(map (init-port #{#'()
#(string-if injected?
#{
    #name  = (#interface)locator.get(#interface .class);
#}
#{
    #name  = new #interface();
    #name .out.name = "#name ";
    #name .out.self = this;#})
#})
    (filter om:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  #port .#direction .#event  = new #(action-type return-type parameter-types)() {public #return-type  action(#parameters) {#(string-if (not (eq? return-type 'void)) #{return #})Runtime.call#(symbol-capitalize direction)(#.model .this, new #(action-type return-type '()) () {public #return-type  action() {#(string-if (not (eq? return-type 'void)) #{return #})#port _#event(#arguments);}}, new Meta(#.model .this.#port , "#event"));};};
   #}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))
  };#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  public #return-type  #port _#event (#parameters) {
  #statement #(if (not (eq? type 'void))
(list "return reply_" (*scope* reply-scope) "_" reply-name ";\n")) };
#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))#
(map (define-function model #{
   public #return-type  #name  (#parameters) {
#statements };
#}) (om:functions model))
}
