##include "#.scope_model .h"

##include <dzn/locator.h>
##include <dzn/runtime.h>
##include <string.h>

#(->string (map (declare-enum model) (om:enums (.behaviour model))))
#(->string (map (enum-to-string model) (om:enums)))
#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {int size;#return-type  (*f)(#((c:scope-name) interface) *#comma #((->join ", ") formal-types));#.scope_model * self;#((->join ";") formal-list)#(if (null? formal-list) "" ";")} args_#port _#event;
#}) (filter (negate (om:dir-matches? port)) (om:events port))))
  (filter om:provides? (om:ports model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {int size;#return-type  (*f)(#.scope_model *#comma #((->join ", ") formal-types));#.scope_model * self;#((->join ";") formal-list)#(if (null? formal-list) "" ";")} args_#port _#event;
#}) (filter (om:dir-matches? port) (om:events port))))
  (om:ports model))

#(map
  (lambda (port)
    (map (define-on model port #{
  static void helper_#port _#event (void* args) {
    args_#port _#event  *a = args;
    a->f(a->self->#port #comma #(comma-space-join (map (lambda (x) (symbol-append 'a-> x)) argument-list)));
  }

    #}) (filter (negate (om:dir-matches? port)) (om:events port))))
  (filter om:provides? (om:ports model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  static void helper_#port _#event(void* args) {
    args_#port _#event  *a = args;
    a->f(a->self#comma #(comma-space-join (map (lambda (x) (symbol-append 'a-> x)) argument-list)));
  }

#}) (filter (om:dir-matches? port) (om:events port))))
  (om:ports model))

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
    runtime_trace_#direction(&port->meta, "#event ");
    args_#port _#event  a = {sizeof(args_#port _#event), #port _#event , port->meta.provides.address#comma #(comma-space-join argument-list)};
    runtime_event(helper_#port _#event , &a);
#(string-if (not (eq? type 'void))
#{ #.scope_model * self_ = port->meta.provides.address;
#}) runtime_trace_out(&port->meta, #(string-if (eq? type 'void) #{"return"#} #{#((c:scope-join) reply-scope)_#reply-name _to_string (self_->reply_#((c:scope-join) reply-scope)_#reply-name)#}));
#(string-if (not (eq? type 'void))
#{ return self_->reply_#((c:scope-join) reply-scope)_#reply-name;
#}) }
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
    static #return-type  call_out_#port _#event(#((c:scope-name) interface) * port#comma #formals) {
    runtime_trace_#direction(&port->meta, "#event ");
    args_#port _#event  a = {sizeof(args_#port _#event), #port _#event , port->meta.requires.address#comma #(comma-space-join argument-list)};
    runtime_defer(port->meta.provides.address, port->meta.requires.address, helper_#port _#event , &a);
}

#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
void #.scope_model _init (#.scope_model * self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
  runtime_info_init(&self->dzn_info, dezyne_locator);
  self->dzn_info.performs_flush = true;
  memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
  #(map (lambda (port) (->string (list "self->" (.name port) " = locator_get(dezyne_locator, \"" ((c:scope-name) (.type port)) "\");\n"))) (filter .injected (om:ports model)))#
((->join  ";\n")
 (filter (negate (compose string-null? string-trim))
   (map (init-member model #{
   #(string-if (not (eq? expression *unspecified*)) #{ self->#name  = #expression#})#}) (om:variables model))))#
(if (null? (om:variables model)) "" ";")
#
   (map
    (lambda (port)
      (string-join
       (append
        (list (->string (list "self->" (.name port) " = &self->" (.name port) "_;\n")))
        (map (define-on model port #{
   self->#port ->#direction .#event  = call_in_#port _#event;
#}) (filter om:in? (om:events port)))
        (list (->string (list "self->" (.name port) "->meta.provides.port = \"" (.name port) "\";\n")))
        (list (->string (list "self->" (.name port) "->meta.provides.address = self;\n")))
        (list (->string (list "self->" (.name port) "->meta.provides.meta = &self->dzn_meta;\n")))
        (list (->string (list "self->" (.name port) "->meta.requires.port = \"" "\";\n")))
        (list (->string (list "self->" (.name port) "->meta.requires.address = 0;\n")))
        (list (->string (list "self->" (.name port) "->meta.requires.meta = 0;\n"))))))
    (filter om:provides? (om:ports model)))#
   (map
    (lambda (port)
      (string-join
       (append
        (if (.injected port)
            '()
            (append
             (list (->string (list "self->" (.name port) " = &self->" (.name port) "_;\n")))
             (list (->string (list "self->" (.name port) "->meta.provides.port = \"" "\";\n")))
             (list (->string (list "self->" (.name port) "->meta.provides.address = 0;\n")))
             (list (->string (list "self->" (.name port) "->meta.provides.meta = 0;\n")))))
        (list (->string (list "self->" (.name port) "->meta.requires.port = \"" (.name port) "\";\n")))
        (list (->string (list "self->" (.name port) "->meta.requires.address = self;\n")))
        (list (->string (list "self->" (.name port) "->meta.requires.meta = &self->dzn_meta;\n")))
        (map (define-on model port #{
    self->#port ->#direction .#event  = call_out_#port _#event;
 #}) (filter om:out? (om:events port))))))
    (filter om:requires? (om:ports model)))}
