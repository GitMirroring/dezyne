;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gaiag.
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag goops)
  :use-module (ice-9 pretty-print)

  :use-module (gaiag om)

  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (ast->))

(define (ast-> ast)
  (parameterize ((indenter #f) (sep " ") (join (->join " "))) (ast:code ast)))
;;(define (ast-> ast) (parameterize ((indenter pretty-printer)) (ast:code ast)))

(define (pretty-printer) (pretty-print (read) :width 120 :max-expr-width 80))

(define (pretty-printer)
  (let loop ((sexp (read)))
    (if (eq? sexp *eof*)
        #f
        (begin
         (pretty-print sexp :width 120 :max-expr-width 80)
         (newline)
         (loop (read))))))
