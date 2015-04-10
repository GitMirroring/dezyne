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


(define-class <modeling> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (p :accessor .p :init-value #f)
  (r :accessor .r :init-value #f))

(define-method (initialize (o <modeling>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.p o)
    (make <dummy>
       :in (make <dummy.in>
              :name 'p
              :self o
              :e (lambda (. args) (call-in o (lambda () (p-e o)) `(,(.p o) e))) )))
  (set! (.r o)
     (make <imodeling>
       :out (make <imodeling.out>
              :name 'r
              :self o
              :f (lambda (. args) (call-out o (lambda () (r-f o)) `(,(.r o) f))) ))))

(define-method (p-e (o <modeling>))
    (action o .r .in .e))

(define-method (r-f (o <modeling>))
    #t)


