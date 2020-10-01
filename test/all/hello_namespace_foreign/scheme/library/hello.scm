(define-module (library hello)
  #:use-module (oop goops)
  #:use-module (dzn runtime)

  #:duplicates (merge-generics)
  #:export (<library:ihello>
    <library:ihello.in>
    <library:ihello.out>
    .hello
    .goodbye
    <library:hello>
    .h
    .w
    .b
    h-hello
    w-howdy
    <library:iworld>
    <library:iworld.in>
    <library:iworld.out>
    .world
    .howdy)
)

(define true #t)
(define false #f)






(define-class <library:ihello.in> (<dzn:port>)
  (hello #:accessor .hello #:init-keyword #:hello)

)

(define-class <library:ihello.out> (<dzn:port>)
  (goodbye #:accessor .goodbye #:init-keyword #:goodbye)

)

(define-class <library:ihello> (<dzn:interface>)
)

(define-class <library:iworld.in> (<dzn:port>)
  (world #:accessor .world #:init-keyword #:world)

)

(define-class <library:iworld.out> (<dzn:port>)
  (howdy #:accessor .howdy #:init-keyword #:howdy)

)

(define-class <library:iworld> (<dzn:interface>)
)
;; (use-modules (library:foreign))


(define-class <library:hello> (<dzn:component>)
  (b #:accessor .b #:init-form true)


  (out_h #:accessor .out_h #:init-value #f #:init-keyword #:out_h)


  (h #:accessor .h #:init-form (make <library:ihello>) #:init-keyword #:h)

  (w #:accessor .w #:init-form (make <library:iworld>) #:init-keyword #:w)

)

(define-method (initialize (o <library:hello>) args)
  (next-method o (cons* #:flushes? #t args))
  (set! (.h o)
    (make <library:ihello>
      #:in (make <library:ihello.in>
        #:name 'h
        #:self o
        #:hello (lambda args (call-in o (lambda _ (apply h-hello (cons o args))) `(,(.h o) hello))))
      #:out (make <library:ihello.out>)))

  (set! (.w o)
    (make <library:iworld>
      #:in (make <library:iworld.in>)
      #:out (make <library:iworld.out>
        #:name 'w
        #:self o
        #:howdy (lambda args (call-out o (lambda _ (apply w-howdy (cons o args))) `(,(.w o) howdy))))))


)


(define-method (h-hello (o <library:hello>))

  (cond (true

      (let ()
        *unspecified*
        (set! (.b o) false)
        (action o .w .in .world )

      )
    )(false
      (((compose .illegal .runtime) o))))
  *unspecified*
)
(define-method (w-howdy (o <library:hello>))

  (cond ((not (.b o))

      (let ()
        *unspecified*
        (set! (.b o) true)
        (action o .h .out .goodbye )

      )
    )((not (not (.b o)))
      (((compose .illegal .runtime) o)))(else ((compose .illegal .runtime) o))
  )
  *unspecified*
)


;; code generator version: 0.0.91-1ed0
