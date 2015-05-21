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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module
  (gaiag table-event) ;;-goeps
  ;;+goeps (g table-event)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language dezyne location)
  :use-module (gaiag misc)
  
  :use-module (oop goops) ;;-goeps
  :use-module (gaiag gom) ;;-goeps
  :use-module (gaiag gaiag) ;;-goeps
  :use-module (gaiag json-table) ;;-goeps
  :use-module (gaiag norm-event) ;;-goeps
  :use-module (gaiag reader) ;;-goeps
  :use-module (gaiag resolve) ;;-goeps
  :use-module (gaiag pretty) ;;-goeps
  :use-module (gaiag table-state) ;;-goeps  

  ;;+goeps :use-module (g ast goops)
  ;;+goeps :use-module (g ast gom)
  ;;+goeps :use-module (g g)
  ;;+goeps :use-module (g json-table)
  ;;+goeps :use-module (g norm-event)
  ;;+goeps :use-module (g pretty)
  ;;+goeps :use-module (g reader)
  ;;+goeps :use-module (g resolve)
  ;;+goeps :use-module (g table-state)  

  :export (ast-> table-event))

(define (table-event model o)
  (norm-event (table-state-statement model o)))

(define (ast-> ast)
  ((compose
    pretty-table
    (mangle-table json-table-event)
    (table table-event)
    ast:resolve) ast))
