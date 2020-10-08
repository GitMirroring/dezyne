(define-module (gaiag c++ew)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (gaiag config)    ;;version
  #:use-module (gaiag command-line) ;;command-line-get
  #:use-module (gaiag dzn)       ;;version
  #:use-module (gaiag code)      ;;version
  #:use-module (gaiag c++)       ;;c++ helper functions
  #:use-module (gaiag misc)      ;;->join
  #:use-module (gaiag templates) ;;define-templates-macro
  #:use-module (gaiag goops)     ;;<root>
  #:use-module (gaiag ast))      ;;??

(define-templates-macro define-templates c++ew)
(include "templates/dzn.scm")
(include "templates/code.scm")
(include "templates/c++.scm")
(include "templates/c++ew.scm") ;;x:header, x:source, ...

(define-method (c++ew:ast-system* (o <root>))
  (filter (negate ast:imported?) (ast:system* o)))

(define-method (c++ew:trigger-type-base (o <trigger>))
  (let ((type ((compose .type .signature .event) o)))
    (match type
      (($ <bool>) "false")
      (($ <int>) (.from (.range type)))
      (($ <enum>) (append (code:type-name type) (list (last (ast:field* type))))))))

(define-method (c++ew:valued-event? (o <trigger>))
  (if (not (is-a? ((compose .type .signature .event) o) <void>))
      o
      ""))

(define-method (c++ew:calling-context-type-name (o <ast>))
  (command-line:get 'calling-context #f))

(define-method (c++ew:formal-names (o <trigger>))
  (map .name (ast:formal* o)))

(define-method (c++ew:port-event-to-trigger (o <port>) (e <event>))
  (make <trigger> #:port.name (.name o)
        #:event.name (.name e)
        #:formals (clone (.formals (.signature e)))))

(define-method (c++ew:port-to-in-trigger* (o <port>))
  (let* ((events (ast:in-event* o)))
    (map (cut c++ew:port-event-to-trigger o <>) events)))

(define-method (c++ew:port-to-out-trigger* (o <port>))
  (let* ((events (ast:out-event* o)))
    (map (cut c++ew:port-event-to-trigger o <>) events)))

(define-method (c++ew:port-type-upcase (o <port>))
  (let* ((type (ast:full-name (.type o)))
         (type (map string-upcase type)))
    (string-join type "_")))

(define (ast-> ast)
  (parameterize ((%x:header x:header) (%x:source #f))
    (code:dump (code:om ast))))
