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

(define-class <function2> (<component>)
  (f :accessor .f :init-value #f)
  (i :accessor .i :init-form (make <interface:ifunction2>)))

(define-method (initialize (o <function2>) args)
  (next-method)
  (set! (.i o)
    (make <interface:ifunction2>
      :in `((a . ,(lambda () (i-a o)))
            (b . ,(lambda () (i-b o)))))))

(define-method (i-a (o <function2>))
  (stderr "function2.i.a\n")
    (cond 
    (#t
      (set! (.f o) (vtoggle o)))))

(define-method (i-b (o <function2>))
  (stderr "function2.i.b\n")
    (cond 
    (#t
      (set! (.f o) (vtoggle o))
      (let ((bb (vtoggle o))) 
      (set! (.f o) bb)
      (action o .i .out 'd)))))

(define-method (vtoggle (o <function2>) )
  (call/cc
   (lambda (return) 
    (cond ((.f o) 
      (action o .i .out 'c)))
    (return (not (.f o))))))


