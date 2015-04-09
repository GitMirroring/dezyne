
(define-class <#.model > (<component>)#
(map (init-member model #{#'()
  (#name  :accessor .#name  :init-value #expression)#})
     (gom:variables model))#
  (delete-duplicates (map (compose declare-replies code:import .type)
                          ((compose .elements .ports) model)))#
  (map (init-port #{#'()
  (#name  :accessor .#name  :init-value ##f)#})
       ((compose .elements .ports) model)))

(define-method (initialize (o <#.model >) args)
  (next-method)#
  (map
    (lambda (port)
    (append
     (list
    "\n"
    "  (set! (." (.name port) " o)\n"
    "    (make <"(.type port)">\n"
    "       :in (make <" (.type port) ".in>")
      (map (define-on model port #{#'()
              :#event  (lambda (. args) (#port -#event  o))#})
    (filter gom:in? (gom:events port)))
    (list ")))")))
    (filter gom:provides? (gom:ports model)))#
(map
    (lambda (port)
    (append
     (list
    "\n"
    "  (set! (." (.name port) " o)\n"
    "     (make <"(.type port)">\n"
    "       :out (make <" (.type port) ".out>")
      (map (define-on model port #{#'()
              :#event  (lambda (. args) (#port -#event  o))#})
          (filter gom:out? (gom:events port)))
   (list ")))")))
   (filter gom:requires? (gom:ports model))))

#(map
   (lambda (port)
     (map (define-on model port #{
(define-method (#port -#event  (o <#.model >))
  (stderr "#.model .#port .#event \n")#statement #(if (not (eq? type 'void))
(list "\n    (.reply-" reply-type "-" reply-name " o)")))

#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
(define-method (#name  (o <#.model >) #parameters )
  (call/cc
   (lambda (return) #statements)))

#}) (gom:functions model))
