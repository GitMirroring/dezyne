(define-class <#.model > (<system>)
  (runtime :accessor .runtime :init-form (make <runtime>) :init-keyword :runtime)
  (parent :accessor .parent :init-value ##f :init-keyword :parent)
  (name :accessor .name :init-value (symbol) :init-keyword :name)#
(map (init-instance #{#'()
  (#name  :accessor .#name  :init-value ##f)#})
     ((compose .elements .instances) model))#
(map (init-bind model #{#'()
  (#port  :accessor .#port  :init-value ##f :init-keyword :#port)#})
     (filter bind-port? ((compose .elements .bindings) model))))

(define-method (initialize (o <#.model >) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (let-keywords
   args ##f ((runtime ##f)
            (name (symbol))
            (parent ##f)
#((->join "\n            ")
 (map (init-bind model #{(#port .#edir  (make <#interface .out>))#})
      (filter bind-port? ((compose .elements .bindings) model)))))#
(map (init-instance #{#'()
  (set! (.#name  o) (make <#component > :runtime (.runtime o) :parent o :name '#name))#})
  ((compose .elements .instances) model))#
(map (init-bind model #{#'()
  (set! (.#port  o) #instance)
  (set! (.#edir  (.#port  o)) #port .#edir)#})
     (filter bind-port? ((compose .elements .bindings) model))))#
(map (connect-ports model #{#'()
  (connect-ports #provided  #required)#})
     (filter (negate bind-port?) ((compose .elements .bindings) model))))
