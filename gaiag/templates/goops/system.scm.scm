(define-class <#.model > (<system>)#
(map (init-instance #{#'()
  (#name  :accessor .#name  :init-form (make <#component >))#})
     ((compose .elements .instances) model))#
(map (init-bind model #{#'()
  (#port  :accessor .#port  :init-value ##f :init-keyword :#port)#})
     (filter bind-port? ((compose .elements .bindings) model))))

(define-method (initialize (o <#.model >) args)
  (next-method)
  (let-keywords
   args ##f (#
((->join "\n            ")
 (map (init-bind model #{(out-#port  ##f)#})
      (filter bind-port? ((compose .elements .bindings) model)))))#
(map (init-bind model #{#'()
  (set! (.#port  o) #instance)
  (set! (.out (.#port  o)) out-#port)#})
     (filter bind-port? ((compose .elements .bindings) model))))#
(map (connect-ports model #{#'()
  (connect-ports #provided  #required)#})
     (filter (negate bind-port?) ((compose .elements .bindings) model))))
