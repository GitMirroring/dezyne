(define-class <#.model > (<component>)#
(map (init-member model #{#'()
  (#name  :accessor .#name  :init-value #expression)#})
     (gom:variables model))#
  (delete-duplicates (map (compose declare-replies code:import .type)
                          ((compose .elements .ports) model)))#
  (map (init-port #{#'()
  (#name  :accessor .#name  :init-form (make <interface:#interface >))#})
       ((compose .elements .ports) model)))

(define-method (initialize (o <#.model >) args)
  (next-method)#
  (map
   (lambda (port)
     (let ((in (filter gom:in? (gom:events port))))
       (list "\n  (set! (." (.name port) " o)"
             (if (null? in)
                 (list "\n    (make <interface:" (.type port) ">)")
                 (list "\n    (make <interface:" (.type port) ">\n"
                       "      :in `("
                       ((->join "\n            ")
                        (map (lambda (event)
                               (list "(" (.name event)  " . ,(lambda () (" (.name port) "-" (.name event) " o)))"))
                             in))
                       "))"))
             ")"))) (filter gom:provides? (gom:ports model)))#
  (map
   (lambda (port)
     (let ((out (filter gom:out? (gom:events port))))
       (list "\n  (set! (." (.name port) " o)"
             (if (null? out)
                 (list "\n    (make <interface:" (.type port) ">)")
                 (list "\n    (make <interface:" (.type port) ">\n"
                       "      :out `("
                       ((->join "\n            ")
                        (map (lambda (event)
                               (list "(" (.name event)  " . ,(lambda () (" (.name port) "-" (.name event) " o)))"))
                             out))
                       "))"))
             ")"))) (filter gom:requires? (gom:ports model))))

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
