(define-class <dezyne:#.scope_model > (<dezyne:system>)#
(map (init-instance #{#'()
  (#name  :accessor .#name  :init-value ##f)#})
     ((compose .elements .instances) model))#
(map (init-bind model #{#'()
  (#port  :accessor .#port  :init-value ##f :init-keyword :#port)#})
     (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model)))))

(define-method (initialize (o <dezyne:#.scope_model >) args)
  (next-method)
  (let-keywords
   args ##f ((locator ##f)
            (name (symbol))
            (parent ##f)
            #((->join "\n            ")
 (map (init-bind model #{(#port .#edir  (make <dezyne:#interface .#edir >))#})
      (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))#
(map (init-instance #{#'()
  (set! (.#name  o) (make <dezyne:#component > :locator (.locator o) :parent o :name '#name))#})
  (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{#'()
  (set! (.locator o) (clone (.locator o)))#
   (map (init-bind model #{#'()
  (set (.locator o) #instance)#}) (injected-bindings model))#})#
(map (init-instance #{#'()
  (set! (.#name  o) (make <dezyne:#component > :locator (.locator o) :parent o :name '#name))#})
  (non-injected-instances model))#
(map (init-bind model #{#'()
  (set! (.#port  o) #instance)
  (set! (.#edir  (.#port  o)) #port .#edir)#})
     (filter bind-port? (filter (negate injected-binding?) ((compose .elements .bindings) model)))))#
(map (connect-ports model #{#'()
  (connect-ports #provided  #required)#})
     (filter (negate bind-port?) ((compose .elements .bindings) model))))
