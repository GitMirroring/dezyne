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


(define-class <Reply7> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (reply-IReply7-E :accessor .reply-IReply7-E :init-value #f)
  (p :accessor .p :init-value #f)
  (r :accessor .r :init-value #f))

(define-method (initialize (o <Reply7>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.p o)
    (make <IReply7>
       :in (make <IReply7.in>
              :name 'p
              :self o
              :foo (lambda (. args) (call-in o (lambda () (apply p-foo (cons o args))) `(,(.p o) foo))) )))
  (set! (.r o)
     (make <IReply7>
       :out (make <IReply7.out>
              :name 'r
              :self o))))

(define-method (p-foo (o <Reply7>) )
    (f o)
    (.reply-IReply7-E o))

(define-method (f (o <Reply7>) )
  (call/cc
   (lambda (return) 
    (let ((v (make <v> :v (action o .r .in .foo)))) 
    (set! (.reply-IReply7-E o) (.v v))))))


