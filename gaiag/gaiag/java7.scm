;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag java7)
  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)

  #:use-module (gaiag deprecated animate)
  #:use-module (gaiag deprecated code)
  #:use-module (gaiag misc)
  #:use-module (gaiag java)
  #:use-module (gaiag reader)

  #:export (ast-> action-type ->type))

(define ast-> ast:code)

(define (action-type model type formals)
  (let* ((formals (.elements formals))
         (count (length formals))
         (formal-types (map (lambda (formal)
                                 (snippet 'formal-type `((type ,(->code model (.type formal))) (out? ,(member (.direction formal) '(inout out))))))
                            formals))
         (formal-types
          (map
           (lambda (p) (if (string-prefix? "final " p) (substring p 6) p))
           formal-types)))
   (list
    (if (is-a? type <void>)
        (list "Action" (if (>0 count) (list count "<" ((->join ", ") formal-types) ">") ""))
        (list "ValuedAction" (if (>0 count) (list count "<" type ", " ((->join ", ") formal-types) ">") (list  "<" type ">")))))))

(define ->type (@@ (gaiag java) ->type))
