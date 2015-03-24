#(map (include-interface #{
import dezyne.#interface
#}) (gom:ports model))
import runtime

class #.model :
#(->string (map declare-enum (gom:enums (.behaviour model))))
    def __init__ (self, parent=None, name=''):
        self.parent = parent
        self.name = name
        self.handling = False
        self.deferred = None
        self.queue = []

#
    (map (init-member model #{
        self.#name  = #expression
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
        self.#name  = dezyne.#interface  (provides=('#name ', self))
#}) (filter gom:provides? ((compose .elements .ports) model)))
#
    (map (init-port #{
        self.#name  = dezyne.#interface  (requires=('#name ', self))
#}) (filter gom:requires? ((compose .elements .ports) model)))
#
   (map
    (lambda (port)
      (map (define-on model port #{
        self.#port .#direction s.#event  = lambda: runtime.call_in (self, self.#port _#event , (self.#port , '#event '))
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map (define-on model port #{
        self.#port .#direction s.#event  = lambda: runtime.call_out (self, self.#port _#event , (self.#port , '#event '))
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model)))
#(map
   (lambda (port)
     (map (define-on model port #{
    def #port _#event  (self):
#statement #(if (not (eq? type 'void))
(list "        return self.reply_" reply-type "_" reply-name))

#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
    def #name  (self#comma #parameters):
#statements
#}) (gom:functions model))
