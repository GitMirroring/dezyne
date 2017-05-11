#(->string (map (declare-enum model) (om:interface-enums model)))
#(->string (map (declare-enum model) (om:enums)))
(define-class <dzn:#.scope_model .in> (<dzn:port-base>)#
  (map (declare-io model #{#'()
  (#name  ##:accessor .#name  ##:init-value ##f ##:init-keyword ##:#name)#})
  (filter om:in? ((compose .elements .events) model))))
(define-class <dzn:#.scope_model .out> (<dzn:port-base>)#
(map (declare-io model #{#'()
  (#name  ##:accessor .#name  ##:init-value ##f ##:init-keyword ##:#name)#})
  (filter om:out? ((compose .elements .events) model))))
(define-class <dzn:#.scope_model > (<dzn:interface>))
