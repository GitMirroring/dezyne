
(define-class <#.model > (<component>)
  (parent :accessor .parent :init-value ##f :init-keyword :parent)
  (name :accessor .name :init-value "" :init-keyword :name)
  (handling :accessor .handling :init-value ##f :init-keyword :handling)
  (flushes :accessor .flushes :init-value ##f :init-keyword :flushes)
  (deferred :accessor .deferred :init-value ##f :init-keyword :deferred)
  (queue :accessor .queue :init-value ##f :init-keyword :queue)#
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
    "       :in (make <" (.type port) ".in>\n"
    "              :name '" (.name port) "\n"
    "              :self o")
      (map (define-on model port #{#'()
              :#event  (lambda (. args) (call-in o (lambda () (#port -#event  o))`(,(.#port  o) '#event))) #})
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
    "       :out (make <" (.type port) ".out>\n"
    "              :name '" (.name port) "\n"
    "              :self o")
      (map (define-on model port #{#'()
              :#event  (lambda (. args) (call-out o (lambda () (#port -#event  o))`(,(.#port  o) '#event))) #})
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
