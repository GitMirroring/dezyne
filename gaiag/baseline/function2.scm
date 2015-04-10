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


(define-class <function2> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (f :accessor .f :init-value #f)
  (i :accessor .i :init-value #f))

(define-method (initialize (o <function2>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <ifunction2>
       :in (make <ifunction2.in>
              :name 'i
              :self o
              :a (lambda (. args) (call-in o (lambda () (apply i-a (cons o args))) `(,(.i o) a))) 
              :b (lambda (. args) (call-in o (lambda () (apply i-b (cons o args))) `(,(.i o) b))) ))))

(define-method (i-a (o <function2>) )
    (cond 
    (#t
      (set! (.f o) (vtoggle o)))))

(define-method (i-b (o <function2>) )
    (cond 
    (#t
      (set! (.f o) (vtoggle o))
      (let ((bb (make <v> :v (vtoggle o)))) 
      (set! (.f o) (.v bb))
      (action o .i .out .d)))))

(define-method (vtoggle (o <function2>) )
  (call/cc
   (lambda (return) 
    (cond ((.f o) 
      (action o .i .out .c)))
    (return (not (.f o))))))


