;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag asserts)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag ast)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag csp)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)

  #:export (
           ast->
	   assert-list
           ))

(define ((assert model) check)
  (if (eq? check 'compliance)
      (list (ast-name model) ((om:scope-name) model) check ((om:scope-name) (.type (om:port model))))
      (list (ast-name model) ((om:scope-name) model) check)))

(define (assert-list o)
  (match o
    (($ <component>)
     (or (and-let* ((component-checks '(deterministic completeness illegal deadlock compliance livelock)))
           (map (assert o) component-checks))
         '()))
    (($ <interface>)
     (if (dzn-async? (.name o))
         '()
         (or (and-let* ((interface-checks '(completeness deadlock livelock)))
                       (map (assert o) interface-checks))
             '())))
    (($ <root>)
     (or (and-let* ((model (find .behaviour (append (om:filter (is? <component>) o)
                                                    (om:filter (is? <interface>) o)))))
                   (assert-list-all model))
         '()))))

(define (assert-list-all o)
  (match o
    (($ <component>)
     (append
      (let ((interfaces (delete-duplicates (sort (map .type (om:ports o)) om:scope.name-equal?))))
        (apply append (map assert-list interfaces)))
      (assert-list o)))
    (($ <interface>) (assert-list o))))

(define (ast-> o)
  ((compose
    assert-list
    parse->om
    ) o))
