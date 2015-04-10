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


(define-class <expressions> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (state :accessor .state :init-value 3)
  (c :accessor .c :init-value 0)
  (i :accessor .i :init-value #f))

(define-method (initialize (o <expressions>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <I>
       :in (make <I.in>
              :name 'i
              :self o
              :e (lambda (. args) (call-in o (lambda () (i-e o)) `(,(.i o) e))) ))))

(define-method (i-e (o <expressions>))
    (cond 
    (#t
      (cond ((equal? (.state o) 0) 
        (set! (.state o) 3)
        (action o .i .out .a))
      (else 
        (set! (.state o) (- (.state o) 1))
        (cond ((< (.c o) (.state o)) 
          (set! (.c o) (+ (.c o) 1)))
        (else 
          (cond ((<= (.c o) ((+ (.state o) 1))) 
            (action o .i .out .lo))
          (else 
            (cond ((> (.c o) (.state o)) 
              (action o .i .out .hi))))))))))))


