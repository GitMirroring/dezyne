;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-module (gaiag runtime)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast)
  #:use-module (gaiag goops)
  #:export (
            %sut
            %instances
            ast->runtime:instance
            runtime:get-sut
            runtime:boundary-port?
            runtime:component-instance?
            runtime:container-eq?
            runtime:container-path
            runtime:find-instance
            runtime:foreign-instance?
            runtime:instance->path
            runtime:instance->string
            runtime:instance->string
            runtime:other-instance+port
            runtime:other-port
            runtime:path->instance
            runtime:port
            runtime:port*
            runtime:port-instance?
            runtime:provides-instance?
            runtime:requires-instance?
            runtime:system-instance?
            runtime:get-system-instances
            <runtime:component>
            <runtime:foreign>
            <runtime:instance>
            <runtime:port>
            <runtime:system>
            <runtime:trigger>
            <runtime>
            .container
            .boundary?
            ))

(define* (runtime:find-instance name container boundary?)
    (find (lambda (i)
            (and (runtime:container-eq? (.container i) container)
                 (eq? (.name (.instance i)) name)
                 (eq? (.boundary? i) boundary?)))
          (%instances)))

(define %sut (make-parameter #f))
(define %instances (make-parameter #f))

(define-class <runtime> ())
(define-class <runtime:instance> (<runtime>)
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance) ;; (is? <instance>)
  (container #:getter .container #:init-value #f #:init-keyword #:container) ;;(is? <runtime:instance>)
  (boundary? #:getter .boundary? #:init-value #f #:init-keyword #:boundary?))

(define-method (write (o <runtime:instance>) port)
  (display "#<" port)
  (display (ast-name o) port)
  (display " " port)
  (display (string-join (map symbol->string (runtime:instance->path o)) ".") port)
  (when (.boundary? o) (display " boundary: #t" port))
  (display ">" port))

(define-class <runtime:component> (<runtime:instance>))
(define-class <runtime:foreign> (<runtime:instance>))
(define-class <runtime:system> (<runtime:instance>))
(define-class <runtime:port> (<runtime:instance>))
(define-class <runtime:trigger> (<runtime>)
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance) ;;<runtime:port>
  (event.name #:getter .event.name #:init-value #f #:init-keyword #:event.name))

(define-method (ast->runtime:instance (o <port>) c)
  (make <runtime:port> #:instance o #:container c))

(define-method (ast->runtime:instance (o <instance>) c)
  (match (.type o)
    (($ <component>) (make <runtime:component> #:instance o #:container c))
    (($ <foreign>) (make <runtime:foreign> #:instance o #:container c))
    (($ <interface>) (make <runtime:port> #:instance o #:container c))
    (($ <system>) (make <runtime:system> #:instance o #:container c))))

(define-method (runtime:container-path (o <runtime:instance>))
  (runtime:container-path o (negate identity)))

(define-method (runtime:container-path (o <runtime:instance>) stop?)
  (unfold stop? identity .container o))

(define-method (runtime:id-container-path (o <runtime:instance>))
  (map .id (runtime:container-path o (negate identity))))

(define-method (runtime:container-eq? (a <runtime:instance>) (b <runtime:instance>))
  (equal? (runtime:id-container-path a) (runtime:id-container-path b)))

(define-method (runtime:container-eq? (a <top>) (b <top>))
  (eq? a b))

(define-method (runtime:port-instance? (o <runtime:instance>))
  (is-a? (.type (.instance o)) <interface>))

(define-method (runtime:provides-instance? (o <runtime:port>))
  (and (runtime:boundary-port? o)
       (or (eq? o (%sut))
           (ast:provides? (.instance o)))))

(define-method (runtime:provides-instance? (o <runtime:instance>))
  #f)

(define-method (runtime:requires-instance? (o <runtime:port>))
  (and (runtime:boundary-port? o)
       (or (eq? o (%sut))
           (ast:requires? (.instance o)))))

(define-method (runtime:requires-instance? (o <runtime:instance>))
  #f)

(define-method (runtime:component-instance? (o <runtime:instance>))
  (is-a? (.type (.instance o)) <component>))

(define-method (runtime:system-instance? (o <runtime:instance>))
  (is-a? (.type (.instance o)) <system>))

(define-method (runtime:foreign-instance? (o <runtime:instance>))
  (is-a? (.type (.instance o)) <foreign>))

(define-method (runtime:foreign-instance? (o <boolean>))
  #f)

(define-method (runtime:instance->string (o <runtime:instance>))
  (let* ((path (runtime:instance->path o))
         (print-path (cond
                      ((is-a? (.type (.instance (%sut)))  <interface>) '(<external>))
                      ((runtime:boundary-port? o) (cons '<external> path))
                      (else path))))
    (string-join (map symbol->string print-path) ".")))

(define-method (runtime:instance->path (o <runtime:instance>))
  (if (runtime:port-instance? (%sut)) '()
      (map (compose .name .instance) (reverse (runtime:container-path o)))))

(define-method (runtime:path->instance (o <list>))
  (or (and (pair? o) (every symbol? o)) (error (format #f "list of symbol expected, got: ~s" o)))
  (let* ((boundary? (= (length o) 1))
         (container (if boundary? (runtime:find-instance (car o) #f #t)
                        (%sut))))
    (let loop ((container container) (instance-path (cdr o)))
      (if (null? instance-path) container
          (let ((container (runtime:find-instance (car instance-path) container #f)))
            (loop container (cdr instance-path)))))))

(define-method (runtime:get-system-instances (o <runtime:instance>))
  (define (end-point-direction? end-point direction instance)
    (and (eq? (.name instance) (.instance.name end-point))
         (find (lambda (p) (and (eq? (.direction p) direction)
                                (eq? (.name p) (.port.name end-point))))
               (ast:port* (.type instance)))))
  (define (binding-direction? b direction instance)
    (or (end-point-direction? (.left b) direction instance)
        (end-point-direction? (.right b) direction instance)))
  (define (order instance* system)
    (let ((binding* (ast:binding* system))
          (winstance* (map (cut cons <> 0) instance*)))
      (let loop ((all winstance*) (todo winstance*) (stable #t))
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

  (define (port->instance p c b)
    (make <runtime:port> #:instance p #:container c #:boundary? b))

  (define (invert-direction p)
    (clone p #:direction (if (eq? (.direction p) 'requires) 'provides 'requires)))

  (append (map (cut port->instance <> #f #t) (filter ast:provides? (runtime:port* o)))
          (let loop  ((o o))
            (pke 'loop-o= o)
            (let ((t (.type (.instance o))))
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
                 (let ((instances (order (ast:instance* t) t)))
                   (cons o (append (map (cut port->instance <> o #f) (runtime:port* o))
                                   (append-map (lambda (i) (loop (ast->runtime:instance i o))) instances))))))))
          (map (cut port->instance <> #f #t) (filter ast:requires? (runtime:port* o)))))

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

(define (pke . rest) (last rest))
;;(use-modules (gaiag misc))
(define-method (runtime:other-port (o <runtime:port>))
  (let loop ((o o) (previous #f))
    (let ((container (pke 'r:o-p 'container= (.container (pke 'r:o-p 'o= o)))))
      (define (outer-runtime-port o)
        (if (eq? (.container o) (%sut)) (runtime:find-instance (.name (.instance o)) #f #t)
            (and
             (not (pke 'boundary-port? (runtime:boundary-port? o)))
             (let* ((other (pke 'other (ast:other-end-point (pke 'oi-instance (.instance container)) (pke 'oi-port (.instance o)))))
                    (other-instance-name (.instance.name other))
                    )
               (if (not other-instance-name) (runtime:find-instance (.port.name other) (.container container) #f)
                   (let ((other-instance (pke 'other-instance (runtime:find-instance (.instance.name other) (.container container) #f))))
                     (runtime:find-instance (.port.name other) other-instance #f)))))))
      (define (inner-runtime-port o)
        (if (and (not (runtime:boundary-port? o))
                 (runtime:foreign-instance? (.container o)))
            (runtime:find-instance (.name (.instance o)) (.container o) #t)
            (let* ((other (ast:other-end-point (.instance o)))
                   (runtime-component (runtime:find-instance (.instance.name other) container #f)))
              (runtime:find-instance (.port.name other) runtime-component #f))))

      (define (runtime:system-or-foreign-instance? c)
        (and c (or (runtime:system-instance? c) (runtime:foreign-instance? c))))

      (pke 'previous previous)
      (cond ((runtime:boundary-port? o)
             (pke 'port-instance!)
             (let ((next (runtime:find-instance (.name (.instance o)) (or container (%sut)) #f)))
               (cond ((not next) o)
                     ((runtime:component-instance? (.container next)) next)
                     (else (loop next o)))))
            ((runtime:system-instance? container)
             (pke 'system-instance!)
             (let* ((inner (pke 'inner-runtime-port (inner-runtime-port o)))
                    (outer (pke 'outer-runtime-port (outer-runtime-port o)))
                    (next (pke 'next (if (eq? inner previous) outer inner))))
               (cond ((runtime:boundary-port? next) next)
                     ((runtime:system-or-foreign-instance? (.container next)) (loop next o))
                     (else next))))
            ((runtime:foreign-instance? container)
             (pke 'foreign-instance!)
             (let* ((inner (pke 'inner (inner-runtime-port o)))
                    (outer (pke 'outer (outer-runtime-port o)))
                    (next (pke 'next (if (eq? inner previous) outer inner))))
               (cond ((runtime:boundary-port? next) next)
                     ((runtime:system-or-foreign-instance? (.container next)) (loop next o))
                     (else next))))
            ((runtime:component-instance? container)
             (pke 'component-instance!)
             (let ((next (pke 'outer-runtime-port (outer-runtime-port o))))
               (cond ((runtime:system-or-foreign-instance? (.container next)) (loop next o))
                (else next))))))))

(define-method (runtime:port (o <runtime:component>) (port <port>))
  (runtime:find-instance (.name port) o #f))

(define-method (runtime:port (o <runtime:port>) x)
  o)

(define-method (runtime:other-instance+port (instance <runtime:component>) (port <runtime:port>))
  (let* ((other-port (runtime:other-port port))
         (other-instance (if (runtime:boundary-port? other-port) other-port
                             (.container other-port))))
    (values other-instance other-port)))

(define-method (runtime:other-instance+port (instance <runtime:port>))
  (let ((other-port (runtime:other-port instance)))
    (values (.container other-port) other-port)))

(define-method (runtime:boundary-port? (o <runtime:port>))
  (or (eq? o (%sut))
      (.boundary? o)))

(define-method (runtime:boundary-port? (o <runtime:instance>))
  #f)

(define-method (runtime:port* (o <runtime:instance>))
  (if (runtime:port-instance? o) '() (ast:port* (.type (.instance o)))))

(define* (runtime:get-sut root #:optional (model (ast:get-model root)))
  (let* ((sut (make <instance> #:name 'sut #:type.name (.name model)))
         (root (clone root #:elements (cons sut (ast:top* root)))))
    (ast->runtime:instance (clone sut #:parent root) #f)))
