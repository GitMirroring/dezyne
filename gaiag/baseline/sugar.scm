;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


(define-class <sugar> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (s :accessor .s :init-value '(Enum False))
  (i :accessor .i :init-value #f))

(define-method (initialize (o <sugar>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <I>
       :in (make <I.in>
              :name 'i
              :self o
              :e (lambda (. args) (call-in o (lambda () (apply i-e (cons o args))) `(,(.i o) e))) ))))

(define-method (i-e (o <sugar>) )
    (cond 
    ((equal? (.s o) '(Enum False))
      (cond ((equal? (.s o) '(Enum False)) 
        (action o .i .out .a))
      (else 
        (let ((t (make <v> :v '(Enum False)))) 
        (cond ((equal? (.v t) '(Enum True)) 
          (action o .i .out .a)))))))))


