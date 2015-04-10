;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


(define-class <Guardthreetopon> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (b :accessor .b :init-value #f)
  (i :accessor .i :init-value #f)
  (r :accessor .r :init-value #f))

(define-method (initialize (o <Guardthreetopon>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.i o)
    (make <IGuardthreetopon>
       :in (make <IGuardthreetopon.in>
              :name 'i
              :self o
              :e (lambda (. args) (call-in o (lambda () (i-e o)) `(,(.i o) e))) 
              :t (lambda (. args) (call-in o (lambda () (i-t o)) `(,(.i o) t))) 
              :s (lambda (. args) (call-in o (lambda () (i-s o)) `(,(.i o) s))) )))
  (set! (.r o)
     (make <RGuardthreetopon>
       :out (make <RGuardthreetopon.out>
              :name 'r
              :self o
              :a (lambda (. args) (call-out o (lambda () (r-a o)) `(,(.r o) a))) ))))

(define-method (i-e (o <Guardthreetopon>))
    (cond 
    ((and #t (.b o))
      (action o .i .out .a))
    ((and #t (not (.b o)))
      (let ((c #t)) 
      (cond (c 
        (action o .i .out .a)))))))

(define-method (i-t (o <Guardthreetopon>))
    (cond 
    ((.b o)
      (action o .i .out .a))
    ((not (.b o))
      (action o .i .out .a))))

(define-method (i-s (o <Guardthreetopon>))
    (action o .i .out .a))

(define-method (r-a (o <Guardthreetopon>))
    #t)


