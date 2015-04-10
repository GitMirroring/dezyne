;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


(define-class <Reply5> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (dummy :accessor .dummy :init-value #f)
  (reply-I-Status :accessor .reply-I-Status :init-value #f)
  (reply-U-Status :accessor .reply-U-Status :init-value #f)
  (i :accessor .i :init-value #f)
  (u :accessor .u :init-value #f))

(define-method (initialize (o <Reply5>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <I>
       :in (make <I.in>
              :name 'i
              :self o
              :done (lambda (. args) (call-in o (lambda () (apply i-done (cons o args))) `(,(.i o) done))) )))
  (set! (.u o)
     (make <U>
       :out (make <U.out>
              :name 'u
              :self o))))

(define-method (i-done (o <Reply5>) )
    (cond 
    (#t
      (let ((s (make <v> :v (action o .u .in .what)))) 
      (set! (.v s) (action o .u .in .what))
      (cond ((equal? (.v s) '(Status Ok)) 
        (let ((s (make <v> :v (fun o)))) 
        (set! (.reply-I-Status o) (.v s))))
      (else 
        (let ((s (make <v> :v (fun_arg o '(Status No))))) 
        (set! (.reply-I-Status o) (.v s))))))))
    (.reply-I-Status o))

(define-method (fun (o <Reply5>) )
  (call/cc
   (lambda (return) 
    (return '(Status Yes)))))

(define-method (fun_arg (o <Reply5>) s)
  (call/cc
   (lambda (return) 
    (return s))))


