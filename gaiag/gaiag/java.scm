;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (gaiag om)

  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (ast-> lambda-type ->type))

(define ast-> ast:code)

(define (lambda-type model type formals)
  (let* ((formals (.elements formals))
         (count (length formals))
         (formal-types (map (lambda (formal)
                                 (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                            formals)))
   (list
    (if (eq? (.name type) 'void)
        (list "Action" (if (>0 count) (list count "<" ((->join ", ") formal-types) ">") ""))
        (list "ValuedAction" (if (>0 count) (list count "<" type ", " ((->join ", ") formal-types) ">") (list  "<" type ">")))))))

(define (->type type)
  (cond
   ((equal? type "int") "Integer")
   ((equal? type "boolean") "Boolean")
   (else type)))
