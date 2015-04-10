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


(define-class <GuardedRequiredIllegal> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (c :accessor .c :init-value #f)
  (t :accessor .t :init-value #f)
  (b :accessor .b :init-value #f))

(define-method (initialize (o <GuardedRequiredIllegal>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.t o)
    (make <Top>
       :in (make <Top.in>
              :name 't
              :self o
              :unguarded (lambda (. args) (call-in o (lambda () (t-unguarded o)) `(,(.t o) unguarded))) 
              :e (lambda (. args) (call-in o (lambda () (t-e o)) `(,(.t o) e))) )))
  (set! (.b o)
     (make <Bottom>
       :out (make <Bottom.out>
              :name 'b
              :self o
              :f (lambda (. args) (call-out o (lambda () (b-f o)) `(,(.b o) f))) ))))

(define-method (t-unguarded (o <GuardedRequiredIllegal>))
    #t)

(define-method (t-e (o <GuardedRequiredIllegal>))
    (cond 
    ((not (.c o))
      (set! (.c o) #t)
      (action o .b .in .e))
    ((.c o)
      #t)))

(define-method (b-f (o <GuardedRequiredIllegal>))
    (cond 
    ((not (.c o))
      (illegal))
    ((.c o)
      (set! (.c o) #f))))


