import sys
#(map (include-interface #{
import dezyne.#interface
#}) (om:ports model))
import runtime
from runtime import V

class #.model  (runtime.Component):
#(->string (map (declare-enum model) (append (om:enums (.behaviour model)) (om:enums))))
    def __init__ (self, loc, name='', parent=None):
        runtime.Component.__init__ (self, loc, name, parent)
        loc.get (runtime.Runtime).flushes (self)
#
    (map (init-member model #{
#(string-if (eq? expression *unspecified*) "" #{         self.#name  = #expression
#})#}) (om:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))#
    (map (init-port #{
        self.#name  = dezyne.#interface  (provides=runtime.Port ('#name ', self))
#}) (filter om:provides? ((compose .elements .ports) model)))#
    (map (init-port #{
#(string-if injected?
#{
        self.#name  = loc.get (dezyne.#interface)
#}
#{
        self.#name  = dezyne.#interface  (requires=runtime.Port ('#name ', self))
#})
#}) (filter om:requires? ((compose .elements .ports) model)))
#
   (map
    (lambda (port)
      (map (define-on model port #{
        self.#port .#direction port.#event  = lambda *args: runtime.#(string-if (eq? return-type 'void) "" "r")call_in (self, lambda: self.#port _#event  (*args), (self.#port , '#event '#(string-if (not (eq? type 'void))#{, self.#port .#reply-name _to_string#})))
#}) (filter om:in? (om:events port))))
    (filter om:provides? (om:ports model)))#
   (map
    (lambda (port)
      (map (define-on model port #{
        self.#port .#direction port.#event  = lambda *args: runtime.call_out (self, lambda: self.#port _#event  (*args), (self.#port , '#event '))
#}) (filter om:out? (om:events port))))
    (filter om:requires? (om:ports model)))
#(map
   (lambda (port)
     (map (define-on model port #{
    def #port _#event  (self#comma #arguments):
#statement #(if (not (eq? type 'void))
(list "        return self.reply_" (*scope* reply-scope) "_" reply-name))

#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))#
(map (define-function model #{
    def #name  (self#comma #formals):
#statements
#}) (om:functions model))
