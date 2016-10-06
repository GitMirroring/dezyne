;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag cs)
  :use-module (srfi srfi-26)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag om)

  :use-module (gaiag animate)
  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (ast-> lambda-type))

(define ast-> ast:code)

(define (lambda-type model type formals)
  (let* ((formals (.elements formals))
         (count (length formals))
         (formal-types (map (lambda (formal)
                                 (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                            formals)))
   (list
    (if (eq? (.name type) 'void)
        (list "Action" (if (>0 count) (list "<" ((->join ", ") formal-types) ">") ""))
        (list "Func" (if (>0 count) (list "<"((->join ", ") formal-types) "," type ">") (list  "<" type ">")))))))
