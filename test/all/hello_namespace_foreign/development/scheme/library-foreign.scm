(define-module (library foreign)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn runtime)
  #:use-module (library hello)
  #:duplicates (merge-generics)
  #:export (
    <library:foreign>
    w-world)
  #:re-export (.w))

(define-class <library:foreign> (<dzn:component>)
  (out_w #:accessor .out_w #:init-value #f #:init-keyword #:out_w)
  (w #:accessor .w #:init-form (make <library:iworld>) #:init-keyword #:w))

(define-method (initialize (o <library:foreign>) args)
  (next-method)
  (set! (.w o)
    (make <library:iworld>
      #:in (make <library:iworld.in>
        #:name 'w
        #:self o
        #:world (lambda args (call-in o (lambda _ (apply w-world (cons o args))) `(,(.w o) world))))
      #:out (make <library:iworld.out>))))

(define-method (w-world (o <library:foreign>))
  #t)
