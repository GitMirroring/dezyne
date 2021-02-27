;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gaiag vm runtime)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (gaiag misc)
  #:use-module (ice-9 poe)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast)
  #:use-module (gaiag goops)
  #:export (%sut
            %instances
            ast->runtime:instance
            runtime:get-sut
            runtime:boundary-port?
            runtime:component-instance?
            runtime:container-eq?
            runtime:container-path
            runtime:dotted-name
            runtime:foreign-instance?
            runtime:instance->path
            runtime:instance->string
            runtime:kind
            runtime:other-instance+port
            runtime:other-port
            runtime:path->instance
            runtime:port
            runtime:port*
            runtime:port-instance?
            runtime:port-name->instance
            runtime:provides-instance?
            runtime:requires-instance?
            runtime:system-instance?
            runtime:system*
            <runtime:component>
            <runtime:foreign>
            <runtime:instance>
            <runtime:port>
            <runtime:system>
            <runtime:trigger>
            <runtime>
            .container
            .boundary?
            .rank))

;;;
;;; Commentary:
;;;
;;; The Dezyne VM runtime AST.
;;;
;;; Code:

;;; The runtime instances.
(define %instances (make-parameter #f))

;;; The system under test.
(define %sut (make-parameter #f))


;;;
;;; Runtime AST.
;;;
(define-class <runtime> ())
(define-class <runtime:instance> (<runtime>)
  (ast #:getter .ast #:init-value #f #:init-keyword #:ast) ;; (is? <port) (is? <instance>)
  (container #:getter .container #:init-value #f #:init-keyword #:container) ;;(is? <runtime:instance>)
  (boundary? #:getter .boundary? #:init-value #f #:init-keyword #:boundary?)
  (rank #:accessor .rank #:init-value 0 #:init-keyword #:rank)) ; set by runtime:rank!

(define-method (runtime:dotted-name (o <runtime:instance>))
  (string-join (runtime:instance->path o) "."))

(define-method (write (o <runtime:instance>) port)
  (display "#<" port)
  (display (ast-name o) port)
  (display " " port)
  (write (runtime:dotted-name o) port)
  (when (.boundary? o) (display " boundary: #t" port))
  (display ">" port))

(define-class <runtime:component-model> (<runtime:instance>))
(define-class <runtime:component> (<runtime:component-model>))
(define-class <runtime:foreign> (<runtime:component-model>))
(define-class <runtime:system> (<runtime:component-model>))
(define-class <runtime:port> (<runtime:instance>))
(define-class <runtime:trigger> (<runtime>)
  (ast #:getter .ast #:init-value #f #:init-keyword #:ast) ;;<runtime:port>
  (event.name #:getter .event.name #:init-value #f #:init-keyword #:event.name))

(define-method (ast->runtime:instance (o <port>) c)
  (make <runtime:port> #:ast o #:container c))

(define-method (ast->runtime:instance (o <instance>) c)
  (match (.type o)
    (($ <component>) (make <runtime:component> #:ast o #:container c))
    (($ <foreign>) (make <runtime:foreign> #:ast o #:container c))
    (($ <interface>) (make <runtime:port> #:ast o #:container c))
    (($ <system>) (make <runtime:system> #:ast o #:container c))))

(define-method (runtime:kind (o <runtime:instance>))
  (match o
    (($ <runtime:port>) (if (runtime:provides-instance? o) 'provides 'requires))
    (($ <runtime:component>) 'component)
    (($ <runtime:foreign>) 'foreign)
    (($ <runtime:system>) 'system)))


;;;
;;; Name, path.
;;;
(define-method (runtime:container-path (o <runtime:instance>))
  (runtime:container-path o (negate identity)))

(define-method (runtime:container-path (o <runtime:instance>) stop?)
  (unfold stop? identity .container o))

(define-method (runtime:id-container-path (o <runtime:instance>))
  (map .id (runtime:container-path o (negate identity))))

(define-method (runtime:instance->string (o <runtime:instance>))
  (let* ((path (runtime:instance->path o))
         (print-path (cond
                      ((is-a? (.type (.ast (%sut))) <interface>) '("<external>"))
                      ((runtime:boundary-port? o) (cons "<external>" path))
                      (else path))))
    (string-join print-path ".")))

(define-method (runtime:instance->path (o <runtime:instance>))
  (if (runtime:port-instance? (%sut)) '()
      (map (compose .name .ast) (reverse (runtime:container-path o)))))

(define-method (runtime:path->instance (o <list>))
  (or (and (pair? o) (every symbol? o)) (error (format #f "list of symbol expected, got: ~s" o)))
  (let* ((boundary? (= (length o) 1))
         (container (if boundary? (runtime:find-instance (car o) #:boundary? #t)
                        (%sut))))
    (let loop ((container container) (instance-path (cdr o)))
      (if (null? instance-path) container
          (let ((container (runtime:find-instance (car instance-path) #:container container)))
            (loop container (cdr instance-path)))))))

(define-method (runtime:port-name->instance (o <string>))
  (find (compose (cut equal? o <>) runtime:dotted-name)
        (filter runtime:boundary-port? (%instances))))


;;;
;;; Predicates.
;;;

(define-method (runtime:boundary-port? (o <runtime:port>))
  (or (eq? o (%sut))
      (.boundary? o)))

(define-method (runtime:boundary-port? o)
  #f)

(define-method (runtime:container-eq? (a <runtime:instance>) (b <runtime:instance>))
  (equal? (runtime:id-container-path a) (runtime:id-container-path b)))

(define-method (runtime:container-eq? (a <top>) (b <top>))
  (eq? a b))

(define-method (runtime:port-instance? o)
  #f)

(define-method (runtime:port-instance? (o <runtime:instance>))
  (is-a? (.type (.ast o)) <interface>))

(define-method (runtime:provides-instance? (o <runtime:port>))
  (and (runtime:boundary-port? o)
       (or (equal? o (%sut))
           (ast:provides? (.ast o)))))

(define-method (runtime:provides-instance? (o <runtime:instance>))
  #f)

(define-method (runtime:requires-instance? (o <runtime:port>))
  (and (runtime:boundary-port? o)
       (or (equal? o (%sut))
           (ast:requires? (.ast o)))))

(define-method (runtime:requires-instance? (o <runtime:instance>))
  #f)

(define-method (runtime:component-instance? (o <runtime:instance>))
  (is-a? (.type (.ast o)) <component>))

(define-method (runtime:system-instance? (o <runtime:instance>))
  (is-a? (.type (.ast o)) <system>))

(define-method (runtime:foreign-instance? (o <runtime:instance>))
  (is-a? (.type (.ast o)) <foreign>))

(define-method (runtime:foreign-instance? (o <boolean>))
  #f)


;;;
;;; Accessors, lookup.
;;;

(define-method (runtime:port (o <runtime:component>) (port <port>))
  (runtime:find-instance (.name port) #:container o))

(define-method (runtime:port (o <runtime:port>) x)
  o)

(define-method (runtime:port* (o <runtime:instance>))
  (if (runtime:port-instance? o) '() (ast:port* (.type (.ast o)))))

(define-method (runtime:other-instance+port (instance <runtime:component>) (port <runtime:port>))
  (let* ((other-port (runtime:other-port port))
         (other-instance (if (runtime:boundary-port? other-port) other-port
                             (.container other-port))))
    (values other-instance other-port)))

(define-method (runtime:other-instance+port (instance <runtime:port>))
  (let ((other-port (runtime:other-port instance)))
    (values (.container other-port) other-port)))

(define-method (runtime:other-instance+port (instance <runtime:port>) (port <runtime:port>))
  (runtime:other-instance+port instance))

(define* (runtime:get-sut root #:optional (model (ast:get-model root)))
  (let* ((sut (make <instance> #:name "sut" #:type.name (.name model)))
         (root (clone root #:elements (cons sut (ast:top* root)))))
    (ast->runtime:instance (clone sut #:parent (.parent model)) #f)))

(define-method (runtime:runtime-requires-port* (o <runtime:component-model>))
  (map (cut runtime:find-instance <> #:container o)
       (map .name ((compose ast:requires-port* .type .ast) o))))

(define* (runtime:find-instance name #:key container boundary?)
    (find (lambda (i)
            (and (runtime:container-eq? (.container i) container)
                 (equal? (.name (.ast i)) name)
                 (equal? (.boundary? i) boundary?)))
          (%instances)))

(define-method (ast:sorted-instance* (o <system>))
  (define (end-point-direction? end-point direction instance)
    (and (equal? (.name instance) (.instance.name end-point))
         (find (lambda (p) (and (eq? (.direction p) direction)
                                (equal? (.name p) (.port.name end-point))))
               (ast:port* (.type instance)))))
  (define (binding-direction? b direction instance)
    (or (end-point-direction? (.left b) direction instance)
        (end-point-direction? (.right b) direction instance)))
  (let ((binding* (ast:binding* o))
        (instances (map (cut cons <> 0) (ast:instance* o))))
    (let loop ((all instances) (todo instances) (stable #t))
      (if (null? todo)
          (if stable (map (cut car <>) (sort all (lambda (a b) (< (cdr a) (cdr b)))))
              (loop all all #t))
          (let* ((winst (car todo))
                 (binding-provides* (filter (lambda (b) (binding-direction? b 'provides (car winst)))
                                            binding*))
                 (above* (filter (lambda (wother)
                                   (find (lambda (b) (binding-direction? b 'requires (car wother)))
                                         binding-provides*))
                                 all))
                 (maxw (if (null? above*) -1 (apply max (map cdr above*))))
                 (w (max (+ 1 maxw) (cdr winst)))
                 (all (if (= w (cdr winst)) all
                          (cons (cons (car winst) w) (alist-delete (car winst) all ast:eq?))))
                 (stable (if (= w (cdr winst)) stable #f)))
            (loop all (cdr todo) stable))))))

(define-method (runtime:system* (o <runtime:instance>) ast:instance*)

  (define (port->instance p c b)
    (make <runtime:port> #:ast p #:container c #:boundary? b))

  (define (invert-direction p)
    (clone p #:direction (if (eq? (.direction p) 'requires) 'provides 'requires)))

  (let ((instances
         (append (map (cut port->instance <> #f #t) (filter ast:provides? (runtime:port* o)))
                 (let loop  ((o o))
                   (let ((t (.type (.ast o))))
                     (match t
                       (($ <interface>) (list o))
                       (($ <component>) (cons o (map (cut port->instance <> o #f) (runtime:port* o))))
                       (($ <foreign>)
                        (let* ((ports (runtime:port* o))
                               (port-instances (map (cut port->instance <> o #f) (runtime:port* o)))
                               (inverted-provides (map invert-direction (filter ast:provides? ports)))
                               (inverted-requires (map invert-direction (filter ast:requires? ports)))
                               (provides-instances (map (cut port->instance <> o #t) inverted-requires))
                               (requires-instances (map (cut port->instance <> o #t) inverted-provides)))
                          (cons o (append port-instances provides-instances requires-instances))))
                       (($ <system>)
                        (let ((instances (ast:instance* t)))
                          (cons o (append (map (cut port->instance <> o #f) (runtime:port* o))
                                          (append-map (lambda (i) (loop (ast->runtime:instance i o))) instances))))))))
                 (map (cut port->instance <> #f #t) (filter ast:requires? (runtime:port* o))))))
    (parameterize ((%instances instances))
      (for-each (cut runtime:rank! <> 0) (filter runtime:provides-instance? instances)))
    instances))

(define-method (runtime:system* (o <runtime:instance>))
  (runtime:system* o ast:sorted-instance*))


;;;
;;; Async, ranking.
;;;

(define-method (runtime:rank! (o <runtime:port>) r)
  (runtime:rank! (.container (runtime:other-port o)) r))

(define-method (runtime:rank! (o <runtime:component-model>) r)
  (when (> r (.rank o))
    (set! (.rank o) r))
  (for-each (lambda (i) (runtime:rank! ((compose .container runtime:other-port) i) (1+ (.rank o)))) (runtime:runtime-requires-port* o)))

(define-method (runtime:rank! (o <boolean>) r)
  *unspecified*)


;;;
;;; Plumbing
;;;

;;OEP (ep, pep)
;;  if (ep on system)
;;  then ep1 = inner oep
;;       ep2 = outer oep ;; #f if system is outermost (=%sut)
;;       next = (ep1 == pep) ? ep2 : ep1
;;       result = (next == #f) ? (the boundary port ep) :
;;                (next on system) ? OEP (next, ep) :
;;                next
;;  else if (ep on component) ;; so pep = #f
;;  then next = outer oep ;; #f if component is outermost (=%sut)
;;       result = (next == #f) ? (the boundary port ep) :
;;                (next on system) ? OEP (next, ep) :
;;                next
;;  else if (ep on interface)
;;  then next = oep on %sut
;;       result = OEP (next, ep)
;;  fi

(define-method (runtime:other-port- (o <runtime:port>))
  (let ((sut (runtime:find-instance "sut")))
    (let loop ((o o) (previous #f))
      (let ((container (.container o)))
        (define (outer-runtime-port o)
          (if (eq? (.container o) sut) (runtime:find-instance (.name (.ast o)) #:boundary? #t)
              (and
               (not (runtime:boundary-port? o))
               (let* ((other (ast:other-end-point (.ast container) (.ast o)))
                      (other-instance-name (and other (.instance.name other))))
                 (cond
                  ((not other) #f) ;; must be injection related
                  ((not other-instance-name)
                   (runtime:find-instance (.port.name other) #:container (.container container)))
                  (else
                   (let ((other-instance (runtime:find-instance (.instance.name other) #:container (.container container))))
                     (runtime:find-instance (.port.name other) #:container other-instance))))))))

        (define (inner-runtime-port o)
          (if (and (not (runtime:boundary-port? o))
                   (runtime:foreign-instance? (.container o)))
              (runtime:find-instance (.name (.ast o)) #:container (.container o) #:boundary? #t)
              (let* ((other (ast:other-end-point (.ast o)))
                     (runtime-component (runtime:find-instance (.instance.name other) #:container container)))
                (runtime:find-instance (.port.name other) #:container runtime-component))))

        (define (injected-port o)
          (let loop ((container container))
            (let ((model (.type (.ast container))))

              (if (not (is-a? model <system>)) (loop (.container container))
                  (let* ((other (ast:other-end-point-injected model (.ast o)))
                         (runtime-component (and other (runtime:find-instance (.instance.name other) #:container container))))
                    (if other (runtime:find-instance (.port.name other) #:container runtime-component)
                        (loop (.container container))))))))

        (define (runtime:system-or-foreign-instance? c)
          (and c (or (runtime:system-instance? c) (runtime:foreign-instance? c))))

        (cond ((runtime:boundary-port? o)
               (let ((next (runtime:find-instance (.name (.ast o)) #:container (or container sut))))
                 (cond ((not next) o)
                       ((runtime:component-instance? (.container next)) next)
                       (else (loop next o)))))
              ((runtime:system-instance? container)
               (let* ((inner (inner-runtime-port o))
                      (outer (outer-runtime-port o))
                      (next (if (eq? inner previous) outer inner)))
                 (cond ((runtime:boundary-port? next) next)
                       ((runtime:system-or-foreign-instance? (.container next)) (loop next o))
                       ((not outer) (injected-port o))
                       (else next))))
              ((runtime:foreign-instance? container)
               (let* ((inner (inner-runtime-port o))
                      (outer (outer-runtime-port o))
                      (next (if (eq? inner previous) outer inner)))
                 (cond ((runtime:boundary-port? next) next)
                       ((runtime:system-or-foreign-instance? (.container next)) (loop next o))
                       (else next))))
              ((runtime:component-instance? container)
               (let ((next (outer-runtime-port o)))
                 (cond
                  ((not next) (injected-port o))
                  ((runtime:system-or-foreign-instance? (.container next)) (loop next o))
                  (else next)))))))))

(define (runtime:other-port o) (runtime:other-port- o))
(define runtime:other-port (pure-funcq runtime:other-port))
