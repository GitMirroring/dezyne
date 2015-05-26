;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
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

(define-module (gaiag java)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

    ;;:use-module (oop goops describe)
  :use-module (gaiag ast)

  :export (ast-> action-type ->type))

(define ast-> ast:code)

(define (action-type type formal-types)
  (let ((count (length formal-types))
        (formal-types
         (map
          (lambda (p) (if (string-prefix? "final " p) (substring p 6) p))
          formal-types)))
   (list
    (if (eq? type 'void)
        (list "Action" (if (>0 count) (list count "<" ((->join ", ") formal-types) ">") ""))
        (list "ValuedAction" (if (>0 count) (list count "<" type ", " ((->join ", ") formal-types) ">") (list  "<" type ">")))))))

(define (->type type)
  (cond
   ((equal? type "int") "Integer")
   ((equal? type "boolean") "Boolean")
   (else type)))


