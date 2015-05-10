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

(define-module (gaiag norm-state)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)
  :use-module (gaiag norm)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (
           ast->
           norm-state
           ))

(define-method (norm-state (o <list>))
  ((compose norm-state ast:resolve ast->gom) o))

(define-method (norm-state (o <ast>))
  ((compose
    remove-skip
    aggregate-on
    expand-on
    aggregate-guard
    flatten-compound
    combine-guards
    passdown-on
    (remove-otherwise '())
    add-skip)
   o))

(define (aggregate-on o)
  "Aggregate triggers with matching port and statement into one on-statement."
  ;; find all ons with matching port and statement
  ;; push all ons into first on, discard the rest
  (match o
    (($ <compound> (($ <on>) ...))
     (make <compound>
       :elements
       (let loop ((ons (.elements o)))
         (if (null? ons)
             '()
             (receive (shared-ons remainder)
                 (partition (lambda (x) (on-same-port-statement? (car ons) x)) ons)
               (let* ((triggers
                       (apply append
                              (map (compose .elements .triggers) shared-ons)))
                      (statement (.statement (car ons)))
                      (aggregated-on (make <on>
                                       :triggers (make <triggers> :elements triggers)
                                       :statement statement)))
                 (cons aggregated-on (loop remainder))))))))
     (($ <functions>) o)
     ((? (is? <ast>)) (gom:map aggregate-on o))
     ((h t ...) (map aggregate-on o))
     (_ o)))

(define-method (on-same-port-statement? (lhs <on>) (rhs <on>))
  (and (eq? ((compose .port car .elements .triggers) lhs)
            ((compose .port car .elements .triggers) rhs))
       (equal? (.statement lhs) (.statement rhs))))

(define (combine-guards o) ;; FIXME: almost identical to passdown-guard
  (match o
    (($ <guard>)
     ((passdown-guard (.expression o)) (.statement o)))
    ((? (is? <ast>)) (gom:map combine-guards o))
    ((h t ...) (map combine-guards o))
    (_ o)))

(define-method (passdown-guard (expression <expression>))
  (lambda (o) (passdown-guard o expression)))

(define-method (passdown-guard (o <top>) (expression <expression>))
  (make <guard> :expression expression :statement o))

(define-method (passdown-guard (o <guard>) (expression <expression>))
  ((passdown-guard
    (make <expression> :value (list 'and
                                    (.value expression)
                                    (.value (.expression o)))))
   (.statement o)))

;; ONLY difference with passdown-guard
(define-method (passdown-guard (o <compound>) (expression <expression>))
  (make <compound> :elements (map (passdown-guard expression) (.elements o))))

(define (passdown-on o)
  (match o
    (($ <on>)
     ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (gom:map passdown-on o))
    ((h t ...) (map passdown-on o))
    (_ o)))

(define-method (passdown-triggers (triggers <triggers>))
  (lambda (o) (passdown-triggers o triggers)))

(define-method (passdown-triggers (o <top>) (triggers <triggers>))
  (make <on> :triggers triggers :statement o))

(define-method (passdown-triggers (o <guard>) (triggers <triggers>))
  (make <guard>
    :expression (.expression o)
    :statement ((passdown-triggers triggers) (.statement o))))

(define-method (passdown-triggers (o <compound>) (triggers <triggers>))
  (let ((statements (.elements o)))
    (match statements
      ((($ <guard>) ...)
       (make <compound>
         :elements (map (passdown-triggers triggers) statements)))
      (_ (make <on> :triggers triggers :statement o)))))

(define (ast-> ast)
  ((compose gom->list norm-state ast:resolve) ast))
