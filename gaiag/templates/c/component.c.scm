##include "#.model .h"

##include "locator.h"
##include "runtime.h"
##include <assert.h>
##include <stdlib.h>
##include <string.h>

#(->string (map declare-enum (gom:enums (.behaviour model))))

#(map
  (lambda (port)
    (map (define-on model port #{
  typedef struct {#.model * self;#((->join "; ") parameter-list)#(if (null? parameter-list) "" ";")} args_#port _#event;
#}) (filter (negate (gom:dir-matches? port)) (gom:events port))))
  (filter gom:provides? (gom:ports model)))

#(map
  (lambda (port)
    (map (define-on model port #{
  static void opaque_#port _#event (void* args) {
    args_#port _#event  *a = args;
    void (*f)(void*#comma #((->join ", ") parameter-list)) = a->self->#port ->#direction .#event;
    f(a->self->#port #comma #(comma-join (map (lambda (x) (symbol-append 'a-> x)) argument-list)));
}

    #}) (filter (negate (gom:dir-matches? port)) (gom:events port))))
  (filter gom:provides? (gom:ports model)))

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
  static #return-type  internal_#port _#event(void* self_#comma #parameters) {
    #.model * self = self_;
    (void)self;
    DZN_LOG("#.model .#port _#event");
    #statement #
    (if (not (eq? type 'void))
(list "    return self->reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#(map
  (lambda (port)
    (map (define-on model port #{
  static #return-type  opaque_#port _#event(void* a) {
    typedef struct {#.model * self;#((->join "; ") parameter-list)#(if (null? parameter-list) "" ";")} args;
  args* b = a;
  internal_#port _#event (b->self#comma #(comma-join (map (lambda (x) (symbol-append 'b-> x)) argument-list)));
  #(if (not (eq? type 'void))
(list "    return b->self->reply_" reply-type "_" reply-name ";\n"
      ))}

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
(map
  (lambda (port)
    (map (define-on model port #{
  static #return-type  #port _#event(void* self_#comma #parameters) {
    #.model * self = ((#interface *)self_)->#direction .self;
    typedef struct {#.model * self;#((->join "; ") parameter-list)#(if (null? parameter-list) "" ";")} args;
  args* a = malloc(sizeof(args));
  a->self=self;
  #((->join ";\n") (map (lambda (x) (symbol-append 'a-> x '= x)) argument-list))#
  (if (null? argument-list) "" ";\n")runtime_event((void(*)(void*))opaque_#port _#event , a);
#(if (not (eq? type 'void))
(list "    return self->reply_" reply-type "_" reply-name ";\n"
      )) }

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
                                     self->#port ->#direction .#event  = #port _#event;
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
                                     self->#port ->#direction .#event  = #port _#event;
                                                 #}) (filter gom:out? (gom:events port))))))
    (filter gom:requires? (gom:ports model)))}
