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
  :use-module (gaiag list match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (gaiag misc)

  :use-module (gaiag ast)
  :use-module (gaiag norm)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :export (
           ast->
           norm-state
           csp-norm-state
           ))

(define (norm-state o)
  ((compose
    remove-skip
    (aggregate-on)
    (expand-on port-equal?)
    aggregate-guard-g
    flatten-compound
    combine-guards
    passdown-on
    (remove-otherwise)
    add-skip
    )
   o))

(define (csp-norm-state o)
  ((compose
    remove-skip
    (aggregate-on on-same-port-statement?)
    (expand-on port-equal?)
    aggregate-guard-g
    flatten-compound
    combine-guards
    passdown-on
    (remove-otherwise)
    add-skip
    )
   o))

(define (on-same-port-statement? lhs rhs)
  (and (is-a? lhs <on>) (is-a? rhs <on>)
       (eq? ((compose .port car .elements .triggers) lhs)
            ((compose .port car .elements .triggers) rhs))
       (equal? (.statement lhs) (.statement rhs))))

(define (port-equal? lhs rhs)
  (and (is-a? lhs <trigger>) (is-a? rhs <trigger>)
       (eq? (.port lhs) (.port rhs))))

(define (port-equal? lhs rhs)
  (and (is-a? lhs <trigger>) (is-a? rhs <trigger>)
       (eq? (.port lhs) (.port rhs))))

(define (combine-guards o)
  (match o
    (($ <guard>)
     ((passdown-expression (.expression o)) (.statement o)))
    ((? (is? <ast>)) (om:map combine-guards o))
    ((h t ...) (map combine-guards o))
    (_ o)))

(define ((passdown-expression expression) o)
  (match o
    (($ <guard>)
     ((passdown-expression
       (make <expression> :value
             (if (om:equal? (.value expression)
                            (.value (.expression o)))
                 (.value expression)
                 (list 'and
                       (.value expression)
                       (.value (.expression o))))))
      (.statement o)))
    (('compound statements ...)
     (let ((statements statements))
       (make <compound>
         :elements (map (passdown-expression expression) statements))))
    (_ (make <guard> :expression expression :statement o))))

(define (passdown-on o)
  (match o
    (($ <on>)
     ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (om:map passdown-on o))
    ((h t ...) (map passdown-on o))
    (_ o)))

(define ((passdown-triggers triggers) o)
  (match o
    (('compound statements ...)
     (let ((statements statements))
       (match statements
         ((($ <guard>) ...)
          (make <compound>
            :elements (map (passdown-triggers triggers) statements)))
         (_ (make <on> :triggers triggers :statement o)))))
    (($ <guard>)
     (make <guard>
       :expression (.expression o)
       :statement ((passdown-triggers triggers) (.statement o))))
    (_ (make <on> :triggers triggers :statement o))))

(define (ast-> ast)
  ((compose
    om->list
    norm-state
    ast:resolve
    ast->om
    ) ast))
