;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  :use-module (gaiag om)

  :use-module (gaiag misc)
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

(define (passdown-on o)
  (match o
    (($ <on>) ((passdown-triggers (.triggers o) (.blocking? o)) (.statement o)))
    ((? (is? <ast>)) (om:map passdown-on o))
    ((h t ...) (map passdown-on o))
    (_ o)))

(define ((passdown-triggers triggers blocking?) o)
  (match o
    (('compound statements ...)
     (let ((statements statements))
       (match statements
         ((($ <guard>) ..1)
          (make <compound>
            :elements (map (passdown-triggers triggers blocking?) statements)))
         (_ (make <on> :triggers triggers :statement o :blocking? blocking?)))))
    (($ <guard>)
     (make <guard>
       :expression (.expression o)
       :statement ((passdown-triggers triggers blocking?) (.statement o))))
    (_ (make <on> :triggers triggers :statement o :blocking? blocking?))))

(define (ast-> ast)
  ((compose
    om->list
    norm-state
    ast:resolve
    ast->om
    ) ast))
