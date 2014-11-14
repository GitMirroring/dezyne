;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <Reply4> (<component>)
  (dummy :accessor .dummy :init-value #f)
  (reply-I-Status :accessor .reply-I-Status :init-value #f)
  (reply-U-Status :accessor .reply-U-Status :init-value #f)
  (i :accessor .i :init-form (make <interface:I>))
  (u :accessor .u :init-form (make <interface:U>)))

(define-method (initialize (o <Reply4>) args)
  (next-method)
  (set! (.i o)
    (make <interface:I>
      :in `((done . ,(lambda () (i-done o))))))
  (set! (.u o)
    (make <interface:U>)))

(define-method (i-done (o <Reply4>))
  (stderr "Reply4.i.done\n")
    (cond 
    (#t
      (let ((s (action o .u .in 'what))) 
      (set! s (action o .u .in 'what))
      (cond ((equal? s '(Status Ok)) 
        (let ((v (fun o))) 
        (cond ((equal? v '(Status Yes)) 
          (set! (.reply-I-Status o) '(Status Yes)))
        (else 
          (set! (.reply-I-Status o) '(Status No))))))
      (else 
        (let ((v (fun_arg o '(Status No)))) 
        (cond ((equal? v '(Status Yes)) 
          (set! (.reply-I-Status o) '(Status Yes)))
        (else 
          (set! (.reply-I-Status o) '(Status No))))))))))
    (.reply-I-Status o))

(define-method (fun (o <Reply4>) )
  (call/cc
   (lambda (return) 
    (return '(Status Yes)))))

(define-method (fun_arg (o <Reply4>) s)
  (call/cc
   (lambda (return) 
    (return s))))


