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
  :use-module (gaiag list match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (language dezyne location)
  :use-module (gaiag misc)

  :use-module (gaiag ast)
  :use-module (gaiag norm)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :export (
           ast->
           code-norm-event
           norm-event
           ))

(define (norm-event o)
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
    add-skip
    )
   o))

(define (code-norm-event o)
  ((compose
    remove-skip
    combine-guards
    (aggregate-on om:triggers-equal?)
    (expand-on equal?)
    aggregate-guard-s
    flatten-compound
    combine-ons
    passdown-guard
    (remove-otherwise)
    add-skip
    )
   o))

(define (aggregate-guard-s o)
  "Aggregate guards with matching statement into one guard-statement."
  ;; find all guands with matching statement
  ;; push all guards into first guard, discard the rest
  (match o
    (('compound ($ <guard>) ..1)
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
     (('functions functions ...) o)
     ((? (is? <ast>)) (om:map aggregate-guard-s o))
     ((h t ...) (map aggregate-guard-s o))
     (_ o)))

(define (guard-same-statement? lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
       (equal? (om->list (.statement lhs)) (om->list (.statement rhs)))))

(define (combine-ons o)
  (match o
    (($ <on>) ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (om:map combine-ons o))
    ((h t ...) (map combine-ons o))
    (_ o)))

(define ((passdown-triggers triggers) o)
  (match o
    (($ <on>)
     ((passdown-triggers
       (retain-source-properties
        (.triggers o)
        (make <triggers> :elements (append triggers (.triggers o)))))
      (.statement o)))
    (('compound statements ...)
     (make <compound> :elements (map (passdown-triggers triggers) statements)))
    (_
     (retain-source-properties
      triggers
      (make <on> :triggers triggers :statement o)))))

(define (passdown-guard o)
  (match o
    (($ <guard>) ((passdown-expression (.expression o)) (.statement o)))
    ((? (is? <ast>)) (om:map passdown-guard o))
    ((h t ...) (map passdown-guard o))
    (_ o)))

(define* ((passdown-expression expression :optional (seen-on? #f)) o)
  (match o
    (($ <on>)
     (make <on>
       :triggers (.triggers o)
       :statement
       (retain-source-properties
        expression
        ((passdown-expression expression #t) (.statement o)))))
    (('compound ($ <guard>) ..1) (=> failure)
     (if seen-on?
         (retain-source-properties
          o
          (make <guard> :expression expression :statement o))
         (failure)))
    ((and ('compound s ...) (? om:declarative?))
     (retain-source-properties
      o
      (make <compound> :elements (map (passdown-expression expression seen-on?) s))))    
    (('compound s ...)
     (retain-source-properties
      expression
      (make <guard> :expression expression :statement o)))
    (($ <guard> e s)
     (let ((o ((passdown-expression e seen-on?) s)))
       (match o
         (($ <on> t s)
          (make <on>
            :triggers t
            :statement
            (retain-source-properties
             expression
             (make <guard> :expression expression :statement s))))
         (('compound t ...)
          (retain-source-properties
           o
           (make <compound>
             :elements (map (passdown-expression expression seen-on?) t))))
         (_
          (retain-source-properties
           expression
           (make <guard> :expression expression :statement o))))))
    (_ (retain-source-properties
        expression
        (make <guard> :expression expression :statement o)))))

(define (ast-> ast)
  ((compose
    om->list
    norm-event
    ast:resolve
    ast->om
    ) ast))
