(define-module (gaiag c++ew)
  #:use-module (gaiag config)    ;;version
  #:use-module (gaiag dzn)       ;;version
  #:use-module (gaiag code)      ;;version
  #:use-module (gaiag templates) ;;define-templates-macro
  #:use-module (gaiag goops)     ;;<root>
  #:use-module (gaiag ast))      ;;??

(define-templates-macro define-templates c++ew)
(include "templates/c++ew.scm") ;;x:header, x:source, ...

(define (ast-> ast)
  (parameterize ((%x:header x:header) (%x:source x:source))
    (code:dump (code:om ast))))
