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


(define-class <requires_twice> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (p :accessor .p :init-value #f)
  (once :accessor .once :init-value #f)
  (twice :accessor .twice :init-value #f))

(define-method (initialize (o <requires_twice>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.p o)
    (make <irequires_twice>
       :in (make <irequires_twice.in>
              :name 'p
              :self o
              :e (lambda (. args) (call-in o (lambda () (p-e o)) `(,(.p o) e))) )))
  (set! (.once o)
     (make <irequires_twice>
       :out (make <irequires_twice.out>
              :name 'once
              :self o
              :a (lambda (. args) (call-out o (lambda () (once-a o)) `(,(.once o) a))) )))
  (set! (.twice o)
     (make <irequires_twice>
       :out (make <irequires_twice.out>
              :name 'twice
              :self o
              :a (lambda (. args) (call-out o (lambda () (twice-a o)) `(,(.twice o) a))) ))))

(define-method (p-e (o <requires_twice>))
    (action o .once .in .e)
    (action o .twice .in .e))

(define-method (once-a (o <requires_twice>))
    #t)

(define-method (twice-a (o <requires_twice>))
    (action o .p .out .a))


