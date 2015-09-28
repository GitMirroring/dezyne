;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag javascript)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag om)

  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (ast->))

(define ast-> ast:code)

(define (javascript:namespace model)
  ((->join ".") (cons 'dezyne (om:scope model))))

(define (javascript:preamble model)
  (->string
   "dzn_require = typeof (require) !== 'undefined' ? require : function () {return {};};\n"
   "dezyne = typeof (dezyne) !== 'undefined' ? dezyne : require (__dirname + '/runtime');\n"
   (let loop ((todo (cons 'dezyne (om:scope model))) (namespace '()))
     (if (null? todo) '()
         (let* ((namespace (append namespace (list (car todo))))
                (o ((->join ".") namespace)))
           (append (list o " = " o " || {};\n" )
                   (loop (cdr todo) namespace)))))))
