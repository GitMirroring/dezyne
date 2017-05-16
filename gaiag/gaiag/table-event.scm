;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag table-event)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 match)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag misc)
  #:use-module (gaiag json-table)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)
  #:use-module (gaiag dzn)
  #:use-module (gaiag table-state)

  #:export (ast-> table-event))

(define (table-event model o)
  ((compose
    table-norm-event
    remove-initial
    (annotate-otherwise)
    (prepend-guards model)
    (annotate-otherwise)
    ) o))

(define (ast-> ast)
  ((compose-root
    dzn-table
    (lambda (x) (if (is-a? x <ast>) (make <root> #:elements (om:filter identity x))
                    (filter identity x)))
    (mangle-table json-table-event)
    (table table-event)
    ast:resolve
    ast->om
    ) ast))
