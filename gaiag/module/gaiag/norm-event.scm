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

(define-module (gaiag norm-event)
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
           norm-event
           ))

(define-method (norm-event (o <list>))
  ((compose norm-event ast:resolve ast->gom) o))

(define-method (norm-event (o <ast>))
  ((compose
    remove-skip
    aggregate-guard
    collapse-on
;;    aggregate-on    
    expand-on
    aggregate-guard
    flatten-compound
    combine-ons
    passdown-guard
    (remove-otherwise '())
    add-skip)
   o))

(define (aggregate-guard o)
  "Aggregate guards with matching statement into one guard-statement."
  ;; find all guands with matching statement
  ;; push all guards into first guard, discard the rest
  (match o
    (($ <compound> (($ <guard>) ...))
     (make <compound>
       :elements
       (let loop ((guards (.elements o)))
         (if (null? guards)
             '()
             (receive (shared-guards remainder)
                 (partition (lambda (x) (guard-same-statement? (car guards) x)) guards)
               (let* ((expression
                       (reduce (lambda (x y)
                                 (list 'or x y))
                               '()
                               (map (compose .value .expression) shared-guards)))
                      (statement (.statement (car guards)))
                      (aggregated-guard (make <guard>
                                          :expression (make <expression>
                                                        :value expression)
                                          :statement statement)))
                 (cons aggregated-guard (loop remainder))))))))
     (($ <functions>) o)
     ((? (is? <ast>)) (gom:map aggregate-guard o))
     ((h t ...) (map aggregate-guard o))
     (_ o)))

(define-method (guard-same-statement? (lhs <guard>) (rhs <guard>))
  (equal? (.statement lhs) (.statement rhs)))

(define (collapse-on o)
  "Collapse matching triggers into one on-statement."
  (match o
    (($ <compound> (($ <on>) ...))
     (make <compound>
       :elements
       (let loop ((ons (.elements o)))
         (if (null? ons)
             '()
             (receive (shared-ons remainder)
                 (partition (lambda (x) (triggers-equal? (car ons) x)) ons)
               (let* ((triggers
                       (delete-duplicates
                        (apply append
                               (map (compose .elements .triggers) shared-ons))))
                      (statement (on-statement (map .statement shared-ons)))
                      (collapsed-on (make <on>
                                       :triggers (make <triggers> :elements triggers)
                                       :statement statement)))
                 (cons collapsed-on (loop remainder))))))))
     (($ <functions>) o)
     ((? (is? <ast>)) (gom:map collapse-on o))
     ((h t ...) (map collapse-on o))
     (_ o)))

(define-method (triggers-equal? (a <on>) (b <on>))
  (equal? ((compose .elements .triggers) a)
          ((compose .elements .triggers) b)))

(define (on-statement statements)
  (if (every identity (map (lambda (x) (equal? x (car statements))) statements))
      (car statements))
  (match statements
    ((($ <guard>) ...) (make <compound> :elements statements))
    ((h t ...) (make <compound> :elements statements))))

(define (combine-ons o)
  (match o
    (($ <on>)
     ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (gom:map combine-ons o))
    ((h t ...) (map combine-ons o))
    (_ o)))

(define-method (passdown-triggers (triggers <triggers>))
  (lambda (o) (passdown-triggers o triggers)))

(define-method (passdown-triggers (o <top>) (triggers <triggers>))
  (make <on> :triggers triggers :statement o))

(define-method (passdown-triggers (o <on>) (triggers <triggers>))
  ((passdown-triggers
    (make <triggers> :elements (append triggers (.triggers o))))
   (.statement o)))

(define-method (passdown-triggers (o <compound>) (triggers <triggers>))
  (make <compound> :elements (map (passdown-triggers triggers) (.elements o))))


(define (passdown-guard o) ;; FIXME: almost identical to combine-guards
  (match o
    (($ <guard>)
     ((passdown-expression (.expression o)) (.statement o)))
    ((? (is? <ast>)) (gom:map passdown-guard o))
    ((h t ...) (map passdown-guard o))
    (_ o)))

(define-method (passdown-expression (expression <expression>))
  (lambda (o) (passdown-expression o expression)))

(define-method (passdown-expression (o <top>) (expression <expression>))
  (make <guard> :expression expression :statement o))

(define-method (passdown-expression (o <on>) (expression <expression>))
  (make <on>
    :triggers (.triggers o)
    :statement ((passdown-expression expression) (.statement o))))

;; ONLY difference with combine-guards
(define-method (passdown-expression (o <compound>) (expression <expression>))
  (let ((statements (.elements o)))
    (match statements
      ((($ <on>) ...)
       (make <compound>
         :elements (map (passdown-expression expression) statements)))
      (_ (make <guard> :expression expression :statement o)))))

(define (ast-> ast)
  ((compose gom->list norm-event ast:resolve) ast))
