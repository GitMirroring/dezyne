;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
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

(define-module (language asd wfc)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (language asd ast)
  :use-module (language asd misc)
  :export (asd-> 
           ))

(define *ast* '())

(define (asd-> ast)
  (display (verify-on ast))
  (display (verify-mixing ast))
  "")

(define (verify-on ast)
  (let ((statements (behaviour-statements (interface-behaviour (interface ast)))))
    (pretty-print statements)
    (if (apply fand (map statement-on statements))
        (stderr "OK\n!")
        (stderr "MULTIPLE ON\n!"))))

(define* (statement-on src :key (count 0))
  (stderr "COUNT: ~a\n" count)
  (stderr "statement-on: ~a\n" src)
  (match src
         (('on e s) (stderr "on: = ~a" s) (if (> count 0) #f (statement-on s :count (1+ count))))
         (('guard expr s) (stderr "guard!: s= ~a" s) (statement-on s :count count))
         (('statements s ...) (apply fand (map (lambda (x) (statement-on x :count count)) s)))
         (('assign x ...) #t)
         (_ (throw "programming error"))))

(define (verify-mixing ast)
  (let ((statements (behaviour-statements (interface-behaviour (interface ast)))))
    (pretty-print statements)
    (if (and #t (map verify-on statements))
        (stderr "OK\n!")
        (stderr "MIXED!"))))
