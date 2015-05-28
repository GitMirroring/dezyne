;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(read-set! keywords 'prefix)

(define-module (gaiag asserts)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)  
  :use-module (gaiag list match)  
  :use-module (srfi srfi-1)

  :use-module (gaiag csp)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

    :use-module (gaiag ast)

  :export (
           ast->
	   assert-list
           ))

(define ((assert model) check)
  (if (eq? check 'compliance)
      (list (ast-name model) (.name model) check (.type (om:port model)))
      (list (ast-name model) (.name model) check)))

(define (assert-list o)
  (match o
    (($ <component>)
     (or (and-let* ((component-checks '(deterministic completeness illegal deadlock compliance livelock)))
                   (map (assert o) component-checks))
         '()))
    (($ <interface>)
     (or (and-let* ((interface-checks '(completeness deadlock livelock)))
                   (map (assert o) interface-checks))
         '()))
    (('root models ...)
     (or (and-let* ((model (om:model-with-behaviour o)))
                   (assert-list-all model))
         '()))
    (_ (assert-list ((om:register (compose ast->om ast:resolve)) o #t)))))

(define (assert-list-all o)
  (match o
    (($ <component>)
     (append
      (let ((interfaces (map om:import (delete-duplicates (sort (map .type ((compose .elements .ports) o)) symbol<)))))
        (apply append (map assert-list interfaces)))
      (assert-list o)))
    (($ <interface>) (assert-list o))))

(define ast-> assert-list)
