;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (g norm-state)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (g ast-colon)
  :use-module (g norm)
  :use-module (g resolve)    
  :use-module (g misc)
  :use-module (g reader)

  :export (ast-> norm-state))

(define (norm-state ast)
  ((compose
    remove-skip
    aggregate-on
    (expand-on port-equal?)
    aggregate-guard
    flatten-compound
    combine-guards
    passdown-on
    (remove-otherwise '())
    add-skip)
   ast))

(define (port-equal? lhs rhs)
  (port-equal?- lhs rhs))

(define (port-equal?- lhs rhs)
  (or (and (symbol? lhs) (symbol? rhs))
      (and (ast:trigger? lhs) (ast:trigger? lhs)
           (eq? (ast:port-name lhs) (ast:port-name rhs)))))

(define (aggregate-on ast)
  "Aggregate triggers with matching port and statement into one on-statement."
;; find all ons with matching port and statement
;; push all ons into first on, discard the rest
  (match ast
    (('compound ('on triggers statement) ...)
     (cons 'compound
               (let loop ((ons (cdr ast)))
                 (if (null? ons)
                     '()
                     (receive (shared-ons remainder)
                         (partition (lambda (x) (on-equal? (car ons) x)) ons)
                       (let* ((triggers (apply append (map ast:triggers shared-ons)))
                              (statement (ast:statement (car ons)))
                              (aggregated-on (list 'on (cons 'triggers triggers) statement)))
                         (cons aggregated-on (loop remainder))))))))
    (('functions f ...) ast)
    ((h ...) (map aggregate-on ast))
    (_ ast)))

(define (on-equal? lhs rhs)
  (and (ast:on? lhs) (ast:on? rhs)
       (and
        (port-equal? (car (ast:triggers lhs)) (car (ast:triggers rhs)))
        (equal? (ast:statement lhs) (ast:statement rhs)))))

(define (combine-guards ast)
  (match ast
    (('guard expression statement) ((passdown-guard expression) statement))
    ((h ...) (map combine-guards ast))
    (_ ast)))

(define ((passdown-guard expression) statement)
  (match statement
    (('compound s ...) (cons 'compound (map (passdown-guard expression) (cdr statement))))
    (('guard g s) ((passdown-guard (list 'and expression g)) s))
    (_ (list 'guard expression statement))))

(define (passdown-on ast)
  (match ast
    (('on ('triggers triggers ...) statement) ((passdown-triggers triggers) statement))
    ((h ...) (map passdown-on ast))
    (_ ast)))

(define ((passdown-triggers triggers) statement)
  (match statement
    (('compound ('guard e s) ...) (cons 'compound (map (passdown-triggers triggers) (cdr statement))))
    (('guard e s) (list 'guard e ((passdown-triggers triggers) s)))
    (_ (list 'on (cons 'triggers triggers) statement))))

(define (ast-> ast)
  ((compose norm-state ast:resolve) ast))
