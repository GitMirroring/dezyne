class #.scope_model  extends Component {#
(->string (map (declare-enum model) (om:enums (.behaviour model))))#
(->string (map declare-integer (om:integers (.behaviour model))))
#
    (map (init-member model #{#'()
  #type  #name;#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{#'()
  #((om:scope-join) interface)  #name;#}) ((compose .elements .ports) model))

  public #.scope_model(Locator locator) {this(locator, "");};

  public #.scope_model(Locator locator, String name) {this(locator, name, null);};

  public #.scope_model(Locator locator, String name, SystemComponent parent) {
    super(locator, name, parent);
    this.flushes = true;#
(map (init-member model #{#'()
    #(string-if (eq? expression (if #f #f)) "" #{#name  = #expression ;#})#}) (om:variables model))#
(map (init-port #{#'()
    #name  = new #((om:scope-join) interface)();
    #name .in.name = "#name ";
    #name .in.self = this;#})
    (filter om:provides? ((compose .elements .ports) model)))#
(map (init-port #{#'()
#(string-if injected?
#{
    #name  = (#((om:scope-join) interface))locator.get(#((om:scope-join) interface) .class);
#}
#{
    #name  = new #((om:scope-join) interface)();
    #name .out.name = "#name ";
    #name .out.self = this;#})
#})
    (filter om:requires? ((compose .elements .ports) model)))#
(map
   (lambda (port)
     (map (define-on model port #{#'()
  #port .#direction .#event  = (#formals) -> {#(string-if (not (is-a? type-type <void>)) #{return #})Runtime.call#(symbol-capitalize direction)(this, () -> {#(string-if (not (is-a? type-type <void>)) #{return #})#port _#event(#arguments);}, new Meta(this.#port , "#event"));};
   #}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))
  }#
(map
   (lambda (port)
     (map (define-on+ model port #{#'()
  public #return-type  #port _#event (#formals) {
  #statement #(if (not (is-a? type-type <void>))
(list "return reply_" ((om:scope-join #f) reply-scope) "_" reply-name ";\n")) };
#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))#
(map (define-function model #{
   public #return-type  #name  (#formals) {
#statements };
#}) (om:functions model))
}
