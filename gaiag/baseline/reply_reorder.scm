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


(define-class <reply_reorder> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (first :accessor .first :init-value #t)
  (p :accessor .p :init-value #f)
  (r :accessor .r :init-value #f))

(define-method (initialize (o <reply_reorder>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.p o)
    (make <Provides>
       :in (make <Provides.in>
              :name 'p
              :self o
              :start (lambda (. args) (call-in o (lambda () (apply p-start (cons o args))) `(,(.p o) start))) )))
  (set! (.r o)
     (make <Requires>
       :out (make <Requires.out>
              :name 'r
              :self o
              :pong (lambda (. args) (call-out o (lambda () (apply r-pong (cons o args))) `(,(.r o) pong))) ))))

(define-method (p-start (o <reply_reorder>) )
    (action o .r .in .ping))

(define-method (r-pong (o <reply_reorder>) )
    (cond 
    ((.first o)
      (action o .p .out .busy)
      (set! (.first o) (not (.first o))))
    ((not (.first o))
      (action o .p .out .finish)
      (set! (.first o) (not (.first o))))))


