(define-class <dzn:#.scope_model > (<dzn:system>)#
(map (init-instance model #{#'()
  (#name  ##:accessor .#name  ##:init-value ##f)#})
     ((compose .elements .instances) model))#
(map (init-bind model #{#'()
  (#port  ##:accessor .#port  ##:init-value ##f ##:init-keyword ##:#port)#})
     (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model)))))

(define-method (initialize (o <dzn:#.scope_model >) args)
  (next-method)
  (let-keywords
   args ##f ((locator ##f)
            (name (symbol))
            (parent ##f)
            #((->join "\n            ")
 (map (init-bind model #{(#port .#edir  (make <dzn:#((om:scope-name) interface) .#edir >))#})
      (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model))))))#
(map (init-instance model #{#'()
  (set! (.#name  o) (make <dzn:#((om:scope-name) component) > ##:locator (.locator o) ##:parent o ##:name '#name))#})
  (injected-instances model))#
(string-if (pair? (injected-bindings model)) #{#'()
  (set! (.locator o) (clone (.locator o)))#
   (map (init-bind model #{#'()
  (set (.locator o) #instance)#}) (injected-bindings model))#})#
(map (init-instance model #{#'()
  (set! (.#name  o) (make <dzn:#((om:scope-name) component) > ##:locator (.locator o) ##:parent o ##:name '#name))#})
  (non-injected-instances model))#
(map (init-bind model #{#'()
  (set! (.#port  o) #instance)
  (set! (.#edir  (.#port  o)) #port .#edir)#})
     (filter om:port-bind? (filter (negate injected-binding?) ((compose .elements .bindings) model)))))#
(map (connect-ports model #{#'()
  (connect-ports #provided  #required)#})
     (filter (negate om:port-bind?) ((compose .elements .bindings) model))))
