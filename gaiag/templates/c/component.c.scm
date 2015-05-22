##include "#.model .h"

##include "locator.h"
##include "runtime.h"
##include <string.h>

#(->string (map (declare-enum model) (om:enums (.behaviour model))))
#(->string (map (enum-to-string model) (om:enums)))
#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {int size;#return-type  (*f)(#interface *#comma #((->join ", ") parameter-types));#.model * self;#((->join ";") parameter-list)#(if (null? parameter-list) "" ";")} args_#port _#event;
#}) (filter (negate (om:dir-matches? port)) (om:events port))))
  (filter om:provides? (om:ports model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {int size;#return-type  (*f)(#.model *#comma #((->join ", ") parameter-types));#.model * self;#((->join ";") parameter-list)#(if (null? parameter-list) "" ";")} args_#port _#event;
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
  static #return-type  #name (#.model * self#comma #parameters);
#}) (om:functions model))

#((->join "\n  ")(map (define-function model #{
  static #return-type  #name (#.model * self#comma #parameters) {
   (void)self;
    #statements }
#}) (om:functions model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  static #return-type  #port _#event(#.model * self#comma #parameters) {
    (void)self;
    #statement #
    (if (not (eq? type 'void))
(list "    return self->reply_" (*scope* reply-scope) "_" reply-name ";\n"
      )) }

#}) (filter (om:dir-matches? port) (om:events port))))
  (om:ports model))#
(map
  (lambda (port)
    (map (define-on model port #{
    static #return-type  call_#direction _#port _#event(#interface * self#comma #parameters) {
                                                                                              runtime_trace_#direction(&self->in, &self->out, "#event ");
    args_#port _#event  a = {sizeof(args_#port _#event), #port _#event , self->#direction .self#comma #(comma-space-join argument-list)};
    runtime_event(helper_#port _#event , &a);
#(string-if (not (eq? type 'void))
#{ #.model * self_ = self->#direction .self; 
#}) runtime_trace_out(&self->in, &self->out, #(string-if (eq? type 'void) #{"return"#} #{#(*scope* reply-scope)_#reply-name _to_string (self_->reply_#(*scope* reply-scope)_#reply-name)#}));
#(string-if (not (eq? type 'void))
#{ return self_->reply_#(*scope* reply-scope)_#reply-name;
#}) }
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
(map
  (lambda (port)
    (map (define-on model port #{
    static #return-type  call_#direction _#port _#event(#interface * self#comma #parameters) {
    runtime_trace_#direction(&self->in, &self->out, "#event ");
    args_#port _#event  a = {sizeof(args_#port _#event), #port _#event , self->#direction .self#comma #(comma-space-join argument-list)};
    component *c = self->out.self;
    runtime_defer(self->in.self, self->out.self, helper_#port _#event , &a);
}

#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
void #.model _init (#.model * self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
  runtime_info_init(&self->dzn_info, dezyne_locator);
  self->dzn_info.performs_flush = true;
  memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
  #(map (lambda (port) (->string (list "self->" (.name port) " = locator_get(dezyne_locator, \"" (.type port) "\");\n"))) (filter .injected (om:ports model)))#
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
        (list (->string (list "self->" (.name port) "->in.name = \"" (.name port) "\";\n")))
        (list (->string (list "self->" (.name port) "->in.self = self;\n")))
        (list (->string (list "self->" (.name port) "->out.name = \"" "\";\n")))
        (list (->string (list "self->" (.name port) "->out.self = 0;\n"))))))
    (filter om:provides? (om:ports model)))#
   (map
    (lambda (port)
      (string-join
       (append
        (if (.injected port)
            '()
            (append
             (list (->string (list "self->" (.name port) " = &self->" (.name port) "_;\n")))
             (list (->string (list "self->" (.name port) "->in.name = \"" "\";\n")))
             (list (->string (list "self->" (.name port) "->in.self = 0;\n")))))
        (list (->string (list "self->" (.name port) "->out.name = \"" (.name port) "\";\n")))
        (list (->string (list "self->" (.name port) "->out.self = self;\n")))
        (map (define-on model port #{
    self->#port ->#direction .#event  = call_out_#port _#event;
 #}) (filter om:out? (om:events port))))))
    (filter om:requires? (om:ports model)))}
