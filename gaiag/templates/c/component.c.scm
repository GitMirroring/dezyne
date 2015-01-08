##include "#.model .h"

##include "locator.h"
##include "runtime.h"
##include <assert.h>

#(->string (map declare-enum (gom:enums (.behaviour model))))

#(map
  (lambda (port)
    (map (define-on model port #{
  static #return-type  #port _#event (void* self_) {
    #.model * self = (#.model *)(self_);
    ASD_LOG("#model .#port _#event");
    #statement #
    (if (not (eq? type 'void))
(list "    return reply_" reply-type "_" reply-name ";\n"
      )) }

#}) (filter (gom:dir-matches? port) (gom:events port))))
  (gom:ports model))#
((->join "\n  ")(map (define-function model #{
  #return-type  #model ::#name (#parameters)
  {
    #statements }
#}) (gom:functions model)))#
'()void #.model _init (#.model *self, locator* dezyne_locator) {
  self->rt = dezyne_locator->runtime_inst;
#((->join  ";\n")
 (map (init-member model #{
   self->#name  = #(if (not (eq? expression *unspecified*)) expression)#}) (gom:variables model)))#
(if (null? (gom:variables model)) "" ";")
#
   (map
    (lambda (port)
      (string-join
       (append
       (map (define-on model port #{
       self->#port .#direction .#event  = #port _#event;
       #}) (filter gom:in? (gom:events port)))
      (list (->string (list "self->" (.name port) ".in.self = self;\n"))))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (string-join
       (append
       (map (define-on model port #{
       self->#port .#direction .#event  = #port _#event;
       #}) (filter gom:out? (gom:events port)))
      (list (->string (list "self->" (.name port) ".out.self = self;\n"))))))
    (filter gom:requires? (gom:ports model))) }
