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

(define-module (language asd asserts)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd reader)

  :use-module (oop goops)
  :use-module (language asd gom)

  :export (
           ast->
	   assert-list
           ))

(define ((assert model) check) (if (eq? check 'compliance)
                                   (list (ast-name model) (.name model) check (.type (gom:port model)))
                                   (list (ast-name model) (.name model) check)))

(define (ast-> ast)
  (pretty-print (assert-list ast))
  "")

(define (assert-list ast)
  (let* ((component-checks '(deterministic illegal deadlock compliance livelock))
	 (interface-checks '(deadlock livelock))
	 (component (gom:component ast))
	 (interfaces (map (compose ast->gom ast:ast .type) ((compose .elements .ports) component))))
    (append (apply append
		   (delete-duplicates (map (lambda (interface)
					     (map (assert interface) interface-checks)) interfaces)))
            (map (assert component) component-checks))))
