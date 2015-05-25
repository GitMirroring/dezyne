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

(define-module
   (g norm-event)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)


   :use-module (g om)
   :use-module (g norm)
   :use-module (g reader)
   :use-module (g resolve)

  :export (
           ast->
           norm-event
           ))

(cond-expand
 (goops-om
  (use-modules (oop goops)))
 (else #t))

(define (norm-event o)
  (match o
    ((and (? (negate (is? <ast>))) (h t ...))
     ((compose norm-event ast:resolve ast->om) o))
    ((? (is? <ast>))
     ((compose
       remove-skip
       aggregate-guard-s
       (aggregate-on om:triggers-equal?)
       (expand-on equal?)
       aggregate-guard-s
       flatten-compound
       combine-ons
       passdown-guard
       (remove-otherwise)
       add-skip)
      o))))

(define (aggregate-guard-s o)
  "Aggregate guards with matching statement into one guard-statement."
  ;; find all guands with matching statement
  ;; push all guards into first guard, discard the rest
  (match o
    (
      ('compound ('guard _ ___) ...)
     (make <compound>
       :elements
       (let loop ((guards (.elements o)))
         (if (null? guards)
             '()
             (receive (shared-guards remainder)
                 (partition (lambda (x) (guard-same-statement? (car guards) x)) guards)
               (if (=1 (length shared-guards))
                   (cons (car shared-guards) (loop remainder))
                   (let* ((expression
                           (reduce (lambda (x y)
                                     (list 'or x y))
                                   '()
                                   (delete-duplicates (map (compose .value .expression) shared-guards) om:equal?)))
                          (statement (.statement (car guards)))
                          (aggregated-guard (make <guard>
                                              :expression (make <expression>
                                                            :value expression)
                                              :statement statement)))
                     (cons aggregated-guard (loop remainder)))))))))
     (('functions _ ___) o)
     ((? (is? <ast>)) (om:map aggregate-guard-s o))
     ((h t ...) (map aggregate-guard-s o))
     (_ o)))

(define (guard-same-statement? lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
       (equal? (om->list (.statement lhs)) (om->list (.statement rhs)))))

(define (combine-ons o)
  (match o
    (('on _ ___)
     ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (om:map combine-ons o))
    ((h t ...) (map combine-ons o))
    (_ o)))

(define ((passdown-triggers triggers) o)
  (match o
    (('on _ ___)
     ((passdown-triggers
       (make <triggers> :elements (append triggers (.triggers o))))
      (.statement o)))
    (('compound _ ___)
     (make <compound> :elements (map (passdown-triggers triggers) (.elements o))))
    (_ (make <on> :triggers triggers :statement o))))

(define (passdown-guard o)
  (match o
    (('guard _ ___)
     ((passdown-expression (.expression o))
      (.statement o)))
    ((? (is? <ast>)) (om:map passdown-guard o))
    ((h t ...) (map passdown-guard o))
    (_ o)))

(define* ((passdown-expression expression :optional (seen-on? #f)) o)
  (match o
    (('on _ ___)
     (make <on>
       :triggers (.triggers o)
       :statement ((passdown-expression expression #t) (.statement o))))
    (
      (('compound ('guard _ _) ..1)) (=> failure)
     (if seen-on?
         (make <guard> :expression expression :statement o)
         (failure)))
    ((and ('compound t ___) (? om:declarative?))
     (make <compound> :elements (map (passdown-expression expression seen-on?) t)))    
    (('compound _ ___) (make <guard> :expression expression :statement o))
    (('guard e s)
     (let ((o ((passdown-expression e seen-on?) s)))
       (match o
         (('on t s)
          (make <on>
            :triggers t
            :statement (make <guard> :expression expression :statement s)))
         (('compound t ___)
          (make <compound>
            :elements (map (passdown-expression expression seen-on?) t)))
         (_ (make <guard> :expression expression :statement o)))))
    (_ (make <guard> :expression expression :statement o))))

(define (ast-> ast)
  ((compose om->list norm-event ast:resolve) ast))
