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


(define-class <imperative> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (state :accessor .state :init-value '(States I))
  (i :accessor .i :init-value #f))

(define-method (initialize (o <imperative>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <iimperative>
       :in (make <iimperative.in>
              :name 'i
              :self o
              :e (lambda (. args) (call-in o (lambda () (i-e o)) `(,(.i o) e))) ))))

(define-method (i-e (o <imperative>))
    (cond 
    ((equal? (.state o) '(States I))
      (action o .i .out .f)
      (action o .i .out .g)
      (action o .i .out .h)
      (set! (.state o) '(States II)))
    ((equal? (.state o) '(States II))
      (set! (.state o) '(States III)))
    ((equal? (.state o) '(States III))
      (action o .i .out .f)
      (action o .i .out .g)
      (action o .i .out .g)
      (action o .i .out .f)
      (set! (.state o) '(States IV)))
    ((equal? (.state o) '(States IV))
      (action o .i .out .h)
      (set! (.state o) '(States I)))))


