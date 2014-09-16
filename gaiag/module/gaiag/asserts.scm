;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag csp)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (gaiag gom)

  :export (
           ast->
	   assert-list
           ))

(define ((assert model) check)
  (if (eq? check 'compliance)
      (list (ast-name model) (.name model) check (.type (gom:port model)))
      (list (ast-name model) (.name model) check)))

(define-method (assert-list (o <component>))
   (or (and-let* ((component-checks '(deterministic illegal deadlock compliance livelock)))
                 (map (assert o) component-checks))
       '()))

(define-method (assert-list (o <interface>))
  (or (and-let* ((interface-checks '(deadlock livelock)))
                (map (assert o) interface-checks))
      '()))

(define-method (assert-list-all (o <component>))
  (append
   (let ((interfaces (map gom:import (delete-duplicates (sort (map .type ((compose .elements .ports) o)) symbol<)))))
     (apply append (map assert-list interfaces)))
   (assert-list o)))

(define-method (assert-list-all (o <interface>))
  (assert-list o))

(define-method (assert-list (o <top>))
  (assert-list ((gom:register (compose ast->gom ast:resolve)) o #t)))

(define-method (assert-list (o <ast>))
  (or (and-let* ((model (gom:model-with-behaviour o)))
                (assert-list-all model))
      '()))

(define ast-> assert-list)
