;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


(define-class <Adaptor> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (state :accessor .state :init-value '(State Idle))
  (count :accessor .count :init-value 0)
  (runner :accessor .runner :init-value #f)
  (choice :accessor .choice :init-value #f))

(define-method (initialize (o <Adaptor>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.runner o)
    (make <IRun>
       :in (make <IRun.in>
              :name 'runner
              :self o
              :run (lambda (. args) (call-in o (lambda () (apply runner-run (cons o args))) `(,(.runner o) run))) )))
  (set! (.choice o)
     (make <IChoice>
       :out (make <IChoice.out>
              :name 'choice
              :self o
              :a (lambda (. args) (call-out o (lambda () (apply choice-a (cons o args))) `(,(.choice o) a))) ))))

(define-method (runner-run (o <Adaptor>) )
    (cond 
    ((and (equal? (.state o) '(State Idle)) (< (.count o) 2))
      (action o .choice .in .e)
      (set! (.state o) '(State Active)))
    ((and (equal? (.state o) '(State Idle)) (not (< (.count o) 2)))
      #t)
    ((equal? (.state o) '(State Active))
      #t)
    ((equal? (.state o) '(State Terminating))
      #t)))

(define-method (choice-a (o <Adaptor>) )
    (cond 
    ((equal? (.state o) '(State Idle))
      #t)
    ((equal? (.state o) '(State Active))
      (set! (.count o) (+ (.count o) 1))
      (action o .choice .in .e)
      (set! (.state o) '(State Terminating)))
    ((and (equal? (.state o) '(State Terminating)) (< (.count o) 2))
      (action o .choice .in .e)
      (set! (.state o) '(State Active)))
    ((and (equal? (.state o) '(State Terminating)) (not (< (.count o) 2)))
      (set! (.state o) '(State Idle)))))


