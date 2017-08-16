;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag table-event)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 match)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag ast)
  #:use-module (gaiag util)

  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag json-table)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag dzn)
  #:use-module (gaiag table-state)

  #:export (ast->
            table-event
            ast->table-event))

(define (table-event model o)
  ((compose
    table-norm-event
    remove-initial
    (annotate-otherwise)
    (prepend-guards model)
    (annotate-otherwise)
    ) o))

(define (ast->table-event ast)
  ((compose
    (table table-event)
    ast:resolve
    parse->om)
   ast))

(define (root->table o)
  (let ((json? (gdzn:command-line:get 'json #f)))
    (if json?
        ((mangle-table json-table-event) o)
        (ast->dzn o)))
  )

(define (ast-> ast)
  ((compose
    root->table
    ast->table-event)
   ast))
