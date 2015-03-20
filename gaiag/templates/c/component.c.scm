##include "#.model .h"

##include "locator.h"
##include "runtime.h"
##include <assert.h>

#(->string (map declare-enum (gom:enums (.behaviour model))))

#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {int size;#return-type  (*f)(#interface *#comma #((->join ", ") parameter-types));#.model * self;#((->join ";") parameter-list)#(if (null? parameter-list) "" ";")} args_#port _#event;
#}) (filter (negate (gom:dir-matches? port)) (gom:events port))))
  (filter gom:provides? (gom:ports model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {int size;#return-type  (*f)(#.model *#comma #((->join ", ") parameter-types));#.model * self;#((->join ";") parameter-list)#(if (null? parameter-list) "" ";")} args_#port _#event;
#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))

#(map
  (lambda (port)
    (map (define-on model port #{
  static void helper_#port _#event (void* args) {
    args_#port _#event  *a = args;
    a->f(a->self->#port #comma #(comma-space-join (map (lambda (x) (symbol-append 'a-> x)) argument-list)));
  }

    #}) (filter (negate (gom:dir-matches? port)) (gom:events port))))
  (filter gom:provides? (gom:ports model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  static void helper_#port _#event(void* args) {
    args_#port _#event  *a = args;
    a->f(a->self#comma #(comma-space-join (map (lambda (x) (symbol-append 'a-> x)) argument-list)));
  }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))

#(map (define-function model #{
  static #return-type  #name (#.model * self#comma #parameters);
#}) (gom:functions model))

#((->join "\n  ")(map (define-function model #{
  static #return-type  #name (#.model * self#comma #parameters) {
   (void)self;
    #statements }
#}) (gom:functions model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  static #return-type  #port _#event(#.model * self#comma #parameters) {
    (void)self;
    DZN_LOG("#.model .#port _#event");
    #statement #
    (if (not (eq? type 'void))
(list "    return self->reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
(map
  (lambda (port)
    (map (define-on model port #{
    static #return-type  call_#direction _#port _#event(#interface * self#comma #parameters) {
    args_#port _#event  a = {sizeof(args_#port _#event), #port _#event , self->#direction .self#comma #(comma-space-join argument-list)};
    #(string-if (eq? direction 'out) #{component *c = self->out.self;
#})
    runtime_#(string-if (eq? direction 'in) #{event(#} #{defer(c->rt, self->in.self, self->out.self, #})helper_#port _#event , &a);
#(string-if (not (eq? type 'void))
#{ #.model * self_ = self->#direction .self;
   return self_->reply_#reply-type _#reply-name;
#}) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))
void #.model _init (#.model * self, locator* dezyne_locator) {
  self->rt = dezyne_locator->rt;
  runtime_set(self->rt, self);
  #(map (lambda (port) (->string (list "self->" (.name port) "_ = *(" (.type port) "*)locator_get(dezyne_locator, \"" (.type port) "\");\n"))) (filter .injected (gom:ports model)))#
((->join  ";\n")
 (filter (negate (compose string-null? string-trim))
   (map (init-member model #{
   #(if (not (eq? expression *unspecified*)) (->string (list 'self-> name " = " expression)))#}) (gom:variables model))))#
(if (null? (gom:variables model)) "" ";")
#
   (map
    (lambda (port)
      (string-join
       (append
        (list (->string (list "self->" (.name port) " = &self->" (.name port) "_;\n")))
        (map (define-on model port #{
   self->#port ->#direction .#event  = call_in_#port _#event;
#}) (filter gom:in? (gom:events port)))
        (list (->string (list "self->" (.name port) "->in.self = self;\n"))))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (string-join
       (append
        (list (->string (list "self->" (.name port) " = &self->" (.name port) "_;\n")))
        (list (->string (list "self->" (.name port) "->out.self = self;\n")))
        (map (define-on model port #{
    self->#port ->#direction .#event  = call_out_#port _#event;
 #}) (filter gom:out? (gom:events port))))))
    (filter gom:requires? (gom:ports model)))}
