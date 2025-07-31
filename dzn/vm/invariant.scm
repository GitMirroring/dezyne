;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn vm invariant)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (dzn ast)
  #:use-module (dzn ast ast)
  #:use-module (dzn misc)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm util)

  #:export (check-invariants))

(define (state-instance?)
  (disjoin
   (is? <runtime:component>)
   (if (is-a? (%sut) <runtime:system>) (is? <runtime:port>)
       runtime:boundary-port?)
   (if (is-a? (%sut) <runtime:port>) (cute eq? <> (%sut))
       (const #f))))

(define* (state-instances #:optional (instances (%instances)))
  (filter (state-instance?) instances))

(define-method (check-invariant (pc <program-counter>) (o <invariant>))
  (%debug "  ~s ~s | ~a=>~a"
          ((compose name .instance) pc) (name o)
          (->sexp (.expression o))
          (true? (eval-expression pc (.expression o))))
  (if (true? (eval-expression pc (.expression o))) '()
      (let ((error (make <invariant-error> #:message "invariant" #:ast o)))
        (list (clone pc #:status error)))))

(define-method (check-invariants (instance <runtime:instance>) (pc <program-counter>))
  (let* ((model (runtime:ast-model instance))
         (behavior (.behavior model))
         (compound (.statement behavior))
         (invariants (filter (is? <invariant>) (ast:statement* compound))))
    (append-map (cute check-invariant pc <>) invariants)))

(define-method (check-invariants (instance <runtime:instance>) trace)
  (let* ((pc (car trace))
         (pc (clone pc #:instance instance)))
    (map (cute cons <> trace)
         (check-invariants instance pc))))

(define-method (check-invariants trace)
  (append-map (cute check-invariants <> trace) (state-instances)))
