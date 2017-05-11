;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag norm-state)

  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 match)
  #:use-module (ice-9 curried-definitions)

  #:use-module (language dezyne location)

  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag compare)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)

  #:export (
           ast->
           norm-state
           csp-norm-state
           ))

(define (norm-state o)
  ((compose
    remove-skip
    (aggregate-on norm:on-statement-equal?)
    (expand-on norm:port-equal?)
    aggregate-guard-g
    flatten-compound
    combine-guards
    passdown-on
    flatten-compound
    (passdown-blocking)
    (remove-otherwise)
    add-skip
    )
   o))

(define (csp-norm-state o)
  ((compose
    remove-skip
    flatten-compound
    (prepend-true-guard)
    (aggregate-on norm:on-same-port-voidness-statement?)
    (expand-on norm:port-and-voidness-equal?)
    aggregate-guard-g
    flatten-compound
    combine-guards
    passdown-on
    flatten-compound
    (passdown-blocking)
    (remove-otherwise)
    add-skip
    )
   o))

(define* ((prepend-true-guard #:optional guard-seen?) o)
  (match o
    (($ <guard>) o)
    (($ <on>) (if guard-seen? o
                  (rsp o (make <guard> #:expression (make <value> #:value 'true) #:statement o))))
    ((? (is? <ast>)) (om:map (prepend-true-guard guard-seen?) o))
    (_ o)))

(define (norm:on-same-port-statement? model lhs rhs)
  (and (is-a? lhs <on>) (is-a? rhs <on>)
       (equal? ((compose .name .port car .elements .triggers) lhs)
               ((compose .name .port car .elements .triggers) rhs))
       (om:equal? (.statement lhs) (.statement rhs))))

(define (norm:on-same-port-voidness-statement? model lhs rhs)
  (and (is-a? lhs <on>) (is-a? rhs <on>)
       (let ((ltrigger ((compose car .elements .triggers) lhs))
             (rtrigger ((compose car .elements .triggers) rhs)))
         (norm:port-and-voidness-equal? model ltrigger rtrigger))
       (om:equal? (.statement lhs) (.statement rhs))))

(define (norm:port-equal? model lhs rhs)
  (and (is-a? lhs <trigger>) (is-a? rhs <trigger>)
       (equal? (.port.name lhs) (.port.name rhs))))

(define (norm:port-and-voidness-equal? model lhs rhs)
    "over een poort? ontvangen we valued of void triggers maar niet
door elkaar want aan de achterkant staat dan een valued reply of void
reply en die kun je niet mixen"
  (and (is-a? lhs <trigger>) (is-a? rhs <trigger>)
       (or (and (om:void? model lhs) (om:void? model rhs))
           (and (not (om:void? model lhs)) (not (om:void? model rhs))))
       (equal? (.port.name lhs) (.port.name rhs))))

(define (passdown-on o)
  (match o
    (($ <on>) ((passdown-triggers (.triggers o)) (.statement o)))
    ((? (is? <ast>)) (om:map passdown-on o))
    (_ o)))

(define ((passdown-triggers triggers) o)
  (match o
    (($ <compound> (statements ...))
       (match statements
         ((($ <guard>) ..1)
          (make <compound>
            #:elements (map (passdown-triggers triggers) statements)))
         (_ (make <on> #:triggers triggers #:statement o))))
    (($ <guard>)
     (make <guard>
       #:expression (.expression o)
       #:statement ((passdown-triggers triggers) (.statement o))))
    (_ (make <on> #:triggers triggers #:statement o))))

(define (ast-> ast)
  ((compose
    om->list
;;    ((@ (gaiag dzn) ast->dzn))
    csp-norm-state
    ast:resolve
    ast->om
    ) ast))
