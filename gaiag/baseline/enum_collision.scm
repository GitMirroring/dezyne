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


(define-class <enum_collision> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (reply-ienum_collision-Retval1 :accessor .reply-ienum_collision-Retval1 :init-value #f)
  (reply-ienum_collision-Retval2 :accessor .reply-ienum_collision-Retval2 :init-value #f)
  (i :accessor .i :init-value #f))

(define-method (initialize (o <enum_collision>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <ienum_collision>
       :in (make <ienum_collision.in>
              :name 'i
              :self o
              :foo (lambda (. args) (call-in o (lambda () (i-foo o)) `(,(.i o) foo))) 
              :bar (lambda (. args) (call-in o (lambda () (i-bar o)) `(,(.i o) bar))) ))))

(define-method (i-foo (o <enum_collision>))
    (set! (.reply-ienum_collision-Retval1 o) '(Retval1 OK))
    (.reply-ienum_collision-Retval1 o))

(define-method (i-bar (o <enum_collision>))
    (set! (.reply-ienum_collision-Retval2 o) '(Retval2 NOK))
    (.reply-ienum_collision-Retval2 o))


