;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <hide> (<component>)
  (b :accessor .b :init-value #f)
  (c :accessor .c :init-value #t)
  (i :accessor .i :init-form (make <interface:I>)))

(define-method (initialize (o <hide>) args)
  (next-method)
  (set! (.i o)
    (make <interface:I>
      :in `((e . ,(lambda () (i-e o)))))))

(define-method (i-e (o <hide>))
  (stderr "hide.i.e\n")
    (cond 
    (#t
      (let ((b (.b o))) 
      (let ((c (g o (.b o) (.c o)))) 
      (cond ((.c o) 
        (action o .i .out 'f))))))))

(define-method (g (o <hide>) b d)
  (call/cc
   (lambda (return) 
    (let ((b d)) 
    (let ((d (.c o))) 
    (action o .i .out 'f)
    (return (or (.b o) d)))))))


