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

(define-module (g norm-event)
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

  :export (ast-> norm-event))

(define (norm-event ast)
  ((compose
    remove-skip
    aggregate-guard
    collapse-on
;;   aggregate-on    
    (expand-on equal?)
    aggregate-guard
    flatten-compound
    combine-ons
    passdown-guard
    (remove-otherwise '())
    add-skip)
   ast))

(define (aggregate-guard o)
  "Aggregate guards with matching statement into one guard-statement."
  ;; find all guands with matching statement
  ;; push all guards into first guard, discard the rest
  (match o
    (('compound ('guard _ _) ...)
     (cons 'compound
           (let loop ((guards (ast:elements o)))
             (if (null? guards)
                 '()
                 (receive (shared-guards remainder)
                     (partition (lambda (x) (guard-same-statement? (car guards) x)) guards)
                       (let* ((expression
                           (reduce (lambda (x y)
                                     (if (equal? x y) x (list 'or x y)))
                                   '()
                                   (map (compose ast:value ast:expression) shared-guards)))
                          (statement (ast:statement (car guards)))
                          (aggregated-guard (list 'guard
                                                  (list 'expression
                                                        expression)
                                                  statement)))
                     (cons aggregated-guard (loop remainder))))))))
     (('functions) o)
     ((h t ...) (map aggregate-guard o))
     (_ o)))

(define (guard-same-statement? lhs rhs)
  (and (ast:is-a? lhs 'guard)
       (ast:is-a? rhs 'guard)
       (equal? (ast:statement lhs) (ast:statement rhs))))

(define (collapse-on o)
  "Collapse matching triggers into one on-statement."
  (match o
    (('compound ('on _ _) ...)
     (cons 'compound
       (let loop ((ons (ast:elements o)))
         (if (null? ons)
             '()
             (receive (shared-ons remainder)
                 (partition (lambda (x) (triggers-equal? (car ons) x)) ons)
               (let* ((triggers
                       (delete-duplicates
                        (apply append
                               (map ast:triggers shared-ons))))
                          (statement (on-statement (map ast:statement shared-ons)))
                      (collapsed-on (list 'on
                                          (cons 'triggers triggers)
                                          statement)))
                 (cons collapsed-on (loop remainder))))))))
     (('functions) o)
     ((h t ...) (map collapse-on o))
     (_ o)))

(define (triggers-equal? a b)
  (equal? (ast:triggers a)
          (ast:triggers b)))

(define (on-statement statements)
  (if (every identity (map (lambda (x) (equal? x (car statements))) statements))
      (car statements))
  (match statements
    ((('guard _ _) ...) (cons 'compound statements))
    ((h t ...) (cons 'compound statements))))

(define (combine-ons o)
  (match o
    (('on)
     ((passdown-triggers (ast:trigger-list o)) (ast:statement o)))
    ((h t ...) (map combine-ons o))
    (_ o)))

(define ((passdown-triggers triggers) o)
  (match o
    (('compound statements ...)
     (cons 'compound (map (passdown-triggers triggers) statements)))
    (('on t s)
     ((passdown-triggers (cons 'triggers (append triggers t))) s))
    (_ (list 'on triggers o))))

(define (passdown-guard o) ;; FIXME: almost identical to combine-guards
  (match o
    (('guard expression statement)
     ((passdown-expression expression) statement))
    ((h t ...) (map passdown-guard o))
    (_ o)))

(define ((passdown-expression expression) o)
  (match o
    (('compound statements ...)
     ;; ONLY difference with combine-guards
     (match statements
       ((('on _ _) ...)
        (cons 'compound
              (map (passdown-expression expression) statements)))
       (_ (list 'guard expression o))))
    (('on t s)
     (list 'on t ((passdown-expression expression) s)))
    (_
     (list 'guard expression o))))

(define (ast-> ast)
  ((compose norm-event ast:resolve) ast))
