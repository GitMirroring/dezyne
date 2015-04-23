import sys
#(map (include-interface #{
import dezyne.#interface
#}) (gom:ports model))
import runtime
from runtime import V

class #.model  (runtime.Component):
#(->string (map (declare-enum model) (append (gom:enums (.behaviour model)) (gom:enums))))
    def __init__ (self, rt, name='', parent=None):
        runtime.Component.__init__ (self, rt, name, parent)
        self.rt.flushes (self)
#
    (map (init-member model #{
#(string-if (eq? expression *unspecified*) "" #{         self.#name  = #expression
#})#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
        self.#name  = dezyne.#interface  (provides=runtime.Port ('#name ', self))
#}) (filter gom:provides? ((compose .elements .ports) model)))#
    (map (init-port #{
        self.#name  = dezyne.#interface  (requires=runtime.Port ('#name ', self))
#}) (filter gom:requires? ((compose .elements .ports) model)))
#
   (map
    (lambda (port)
      (map (define-on model port #{
        self.#port .#direction port.#event  = lambda *args: runtime.call_in (self, lambda: self.#port _#event  (*args), (self.#port , '#event '#(string-if (not (eq? type 'void))#{, self.#port .#reply-name _to_string#})))
#}) (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map (define-on model port #{
        self.#port .#direction port.#event  = lambda *args: runtime.call_out (self, lambda: self.#port _#event  (*args), (self.#port , '#event '))
#}) (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model)))
#(map
   (lambda (port)
     (map (define-on model port #{
    def #port _#event  (self#comma #arguments):
#statement #(if (not (eq? type 'void))
(list "        return self.reply_" (*scope* reply-scope) "_" reply-name))

#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
    def #name  (self#comma #parameters):
#statements
#}) (gom:functions model))
