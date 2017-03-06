##include "#.scope_model .h"

##include <dzn/locator.h>
##include <dzn/runtime.h>
##include <string.h>

#(->string (map (declare-enum model) (om:enums (.behaviour model))))
##if DZN_TRACING
#(->string (map (enum-to-string model) (om:enums)))
##endif // DZN_TRACING

#(map
  (define-helper model #f #{

  typedef struct {uint8_t size;#return-type  (*f)(void*#comma #((->join ", ") formal-types));#.scope_model * self;#((->join ";") formal-numbered-list)#(if (null? formal-list) "" ";")} args_#signature-name;
   #})
   (delete-duplicates (map .signature (append-map (lambda (port) (filter (om:dir-matches? port) (om:events port))) (om:ports model))) (code:signature-types-equal? model)))

#(map
   (lambda (port)
     (let ((signatures (delete-duplicates (map .signature (append-map (lambda (port) (filter (om:dir-matches? port) (om:events port))) (om:ports model))) (code:signature-types-equal? model))))
   (map
      (define-helper model port #{

  static void helper_out_#port _#signature-name (void* args) {
    args_#signature-name  *a = args;
    a->f(a->self->#port #comma #(comma-space-join (map (lambda (x) (symbol-append 'a->_ (number->symbol x))) (iota (length argument-list)))));
  }

    #})
      signatures)))
    (filter om:provides? (om:ports model)))

#(map
   (define-helper model #f #{
      static void helper_in_#signature-name (void* args) {
      args_#signature-name  *a = args;
      a->f(a->self#comma #((->join ", ") (map (lambda (x) (symbol-append 'a->_ (number->symbol x))) (iota (length argument-list)))));
     }
   #})
   (delete-duplicates (map .signature (append-map (lambda (port) (filter (om:dir-matches? port) (om:events port))) (om:ports model))) (code:signature-types-equal? model)))

#(map (define-function model #{
  static #return-type  #name (#.scope_model * self#comma #formals);
#}) (om:functions model))

#((->join "\n  ")(map (define-function model #{
  static #return-type  #name (#.scope_model * self#comma #formals) {
   (void)self;
    #statements }
#}) (om:functions model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  static #return-type  #port _#event(#.scope_model * self#comma #formals) {
    (void)self;
    #statement #
    (if (not (eq? type 'void))
(list "    return self->reply_" ((c:scope-join) reply-scope) "_" reply-name ";\n"
      )) }

#}) (filter (om:dir-matches? port) (om:events port))))
  (om:ports model))#
(map
  (lambda (port)
    (map (define-on model port #{
    static #return-type  call_in_#port _#event(#((c:scope-name) interface) * port#comma #formals) {
    RUNTIME_TRACE_#direction(&port->meta, "#event ");
    #.scope_model * self_ = port->meta.provides.address;
    runtime_start(&self_->dzn_info);
    #port _#event(self_#comma #((->join ", ") argument-list));
    runtime_finish(&self_->dzn_info);
    RUNTIME_TRACE_out(&port->meta, #(string-if (eq? type 'void) #{"return"#} #{#((c:scope-join) reply-scope)_#reply-name _to_string (self_->reply_#((c:scope-join) reply-scope)_#reply-name)#}));
#(string-if (not (eq? type 'void))
#{ return self_->reply_#((c:scope-join) reply-scope)_#reply-name;
#}) }
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
    static #return-type  call_out_#port _#event(#((c:scope-name) interface) * port#comma #formals) {
    RUNTIME_TRACE_#direction(&port->meta, "#event ");
    args_#signature-name  a = {sizeof(args_#signature-name), (#return-type (*)(void*#comma #(comma-space-join formal-types)))#port _#event , port->meta.requires.address#comma #(comma-space-join argument-list)};
    runtime_defer(port->meta.provides.address, port->meta.requires.address, helper_in_#signature-name , &a);
}

#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
void #.scope_model _init (#.scope_model * self, locator* dezyne_locator
##if DZN_TRACING
, dzn_meta_t *dzn_meta
##endif // DZN_TRACING
) {
  runtime_info_init(&self->dzn_info, dezyne_locator);
  self->dzn_info.performs_flush = true;
  #(map (lambda (port) (->string (list "self->" (.name port) " = locator_get(dezyne_locator, \"" ((c:scope-name) (.type port)) "\");\n"))) (filter .injected (om:ports model)))#
((->join  ";\n")
 (filter (negate (compose string-null? string-trim))
   (map (init-member model #{
   #(string-if (not (eq? expression *unspecified*)) #{ self->#name  = #expression#})#}) (om:variables model))))#
(if (null? (om:variables model)) "" ";")
#
   (map (init-port #{
      self->#name = &self->#name _;
      self->#name ->meta.provides.address = self;
      self->#name ->meta.requires.address = 0;
      #(map (define-on model port #{
        self->#port ->#direction .#event  = call_#direction _#port _#event;
      #}) (filter om:in? (om:events port)))
   #})
    (filter om:provides? (om:ports model)))
#
   (map
    (init-port #{
      #(string-if (not (.injected port)) #{
      self->#name = &self->#name _;
      self->#name ->meta.requires.address = self;
      self->#name ->meta.provides.address = 0;
#})
      #(map (define-on model port #{
        self->#port ->#direction .#event  = call_#direction _#port _#event;
      #}) (filter om:out? (om:events port)))
   #})
    (filter om:requires? (om:ports model)))
##if DZN_TRACING
  memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
#
   (map (init-port #{
      self->#name ->meta.provides.port = "#name ";
      self->#name ->meta.provides.meta = &self->dzn_meta;
      self->#name ->meta.requires.port = "";
      self->#name ->meta.requires.meta = 0;
   #})
    (filter om:provides? (om:ports model)))
#
   (map
    (init-port #{
      #(string-if (not (.injected port)) #{
      self->#name ->meta.provides.port = "";
      self->#name ->meta.provides.meta = 0;
      self->#name ->meta.requires.port = "#name ";
      self->#name ->meta.requires.meta = &self->dzn_meta;
#})
   #})
    (filter om:requires? (om:ports model)))
##endif // DZN_TRACING
}
