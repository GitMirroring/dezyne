#(->string (map (declare-enum model) (om:enums model)))
(define-class <dezyne:#.scope_model > (<dezyne:component>)#
(map (init-member model #{#'()
  (#name  :accessor .#name  :init-value #(if (eq? expression *unspecified*) "#f" expression))#})
     (om:variables model))#
  (delete-duplicates (append-map (compose declare-replies code:import .type)
                                 ((compose .elements .ports) model)))#
  (map (init-port #{#'()
  (#name  :accessor .#name  :init-value ##f)#})
       ((compose .elements .ports) model)))
(define-method (initialize (o <dezyne:#.scope_model >) args)
  (next-method)#
  (map
    (lambda (port)
    (append
     (list
    "\n"
    "  (set! (." (.name port) " o)\n"
    "    (make <dezyne:"((om:scope-name) port)">\n"
    "       :in (make <dezyne:" ((om:scope-name) port) ".in>\n"
    "              :name '" (.name port) "\n"
    "              :self o")
      (map (define-on model port #{#'()
              :#event  (lambda (. args) (#(string-if (eq? return-type 'void) "" "r")call-in o (lambda () (apply #port -#event  (cons o args))) `(,(.#port  o) #event #(string-if (not (eq? 'void return-type)) #{  #reply-name  ,#(string-if (null? reply-scope) #{global#} #{#((om:scope-join #f) reply-scope)#})-#reply-name -alist#}))))#})
    (filter om:in? (om:events port)))
    (list ")\n"
     "       :out (make <dezyne:" ((om:scope-name) port) ".out>)))")))
    (filter om:provides? (om:ports model)))#
(map
    (lambda (port)
    (if (.injected port)
    (list "\n  (set! (." (.name port) " o) (get (.locator o) <dezyne:" ((om:scope-name) port) ">))")
    (append
     (list
    "\n"
    "  (set! (." (.name port) " o)\n"
    "     (make <dezyne:"((om:scope-name) port)">\n"
    "       :in (make <dezyne:" ((om:scope-name) port) ".in>)\n"
    "       :out (make <dezyne:" ((om:scope-name) port) ".out>\n"
    "              :name '" (.name port) "\n"
    "              :self o")
      (map (define-on model port #{#'()
              :#event  (lambda (. args) (call-out o (lambda () (apply #port -#event  (cons o args))) `(,(.#port  o) #event))) #})
          (filter om:out? (om:events port)))
   (list ")))"))))
   (filter om:requires? (om:ports model))))

#(map
   (lambda (port)
     (map (define-on model port #{
(define-method (#port -#event  (o <dezyne:#.scope_model >) #formals)#
statement #(if (not (eq? type 'void))
(list "\n    (.reply-" ((om:scope-join #f) reply-scope) "-" reply-name " o)")))

#}) (filter (om:dir-matches? port) (om:events port))))
   (om:ports model))#
(map (define-function model #{
(define-method (#name  (o <dezyne:#.scope_model >) #formals)
  (call/cc
   (lambda (return) #statements)))

#}) (om:functions model))
