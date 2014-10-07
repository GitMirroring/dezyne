import sys
##
#(map (include-interface #{
import interface.#interface
#}) (gom:ports model))

class #.model  ():
#(->string (map declare-enum (gom:enums (.behaviour model))))
    def __init__ (self):
#
    (map (init-member model #{
        self.#name  = #expression
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map (init-port #{
        self.#name  = interface.#interface  ()
#}) ((compose .elements .ports) model))
#
   (map
    (lambda (port)
      (map
       (lambda (event)
         (->string (list "        self." (.name port) ".ins." (.name event) " = "  "self." (.name port) "_" (.name event) "\n")))
       (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map
       (lambda (event)
         (->string (list "        self." (.name port) ".outs." (.name event) " = "  "self." (.name port) "_" (.name event) "\n")))
       (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model)))
#(map
   (lambda (port)
     (map (define-on model port #{
    def #port _#event  (self):
        sys.stderr.write ('#model .#port _#event \n')
#statement #(if (not (eq? type 'void))
(list "        return self.reply_" reply-type))

#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))# (map
 (lambda (function)
   (let* ((signature (.signature function))
          (return-type (python:->code model signature))
          (name (.name function))
          (parameters (.parameters signature))
          (comma (if (null? (.elements parameters)) "" ", "))
          (statement (.statement function))
          (locals (map (lambda (x) (cons (.name x) x)) (.elements parameters)))
          (parameters (python:->code model parameters))
          (statements (python:->code model statement locals 2))
          (model (.name model)))
     (->string (list "    " "def " name " (self" comma parameters "):\n"
                     statements))))
 (gom:functions model))
