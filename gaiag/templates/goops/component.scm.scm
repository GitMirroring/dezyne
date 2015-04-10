
(define-class <#.model > (<component>)
  (handling? :accessor .handling? :init-value ##f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value ##f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value ##f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)#
(map (init-member model #{#'()
  (#name  :accessor .#name  :init-value #expression)#})
     (gom:variables model))#
  (delete-duplicates (map (compose declare-replies code:import .type)
                          ((compose .elements .ports) model)))#
  (map (init-port #{#'()
  (#name  :accessor .#name  :init-value ##f)#})
       ((compose .elements .ports) model)))

(define-method (initialize (o <#.model >) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))#
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
              :#event  (lambda (. args) (call-in o (lambda () (apply #port -#event  (cons o args))) `(,(.#port  o) #event))) #})
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
              :#event  (lambda (. args) (call-out o (lambda () (apply #port -#event  (cons o args))) `(,(.#port  o) #event))) #})
          (filter gom:out? (gom:events port)))
   (list ")))")))
   (filter gom:requires? (gom:ports model))))

#(map
   (lambda (port)
     (map (define-on model port #{
(define-method (#port -#event  (o <#.model >) #parameters)#
statement #(if (not (eq? type 'void))
(list "\n    (.reply-" reply-type "-" reply-name " o)")))

#}) (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))#
(map (define-function model #{
(define-method (#name  (o <#.model >) #parameters)
  (call/cc
   (lambda (return) #statements)))

#}) (gom:functions model))
