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
  (state :accessor .state :init-value '(State Idle))
  (count :accessor .count :init-value 0)
  (runner :accessor .runner :init-form (make <interface:IRun>))
  (choice :accessor .choice :init-form (make <interface:IChoice>)))

(define-method (initialize (o <Adaptor>) args)
  (next-method)
  (set! (.runner o)
    (make <interface:IRun>
      :in `((run . ,(lambda () (runner-run o))))))
  (set! (.choice o)
    (make <interface:IChoice>
      :out `((a . ,(lambda () (choice-a o)))))))

(define-method (runner-run (o <Adaptor>))
  (stderr "Adaptor.runner.run\n")
    (cond 
    ((and (equal? (.state o) '(State Idle)) (< (.count o) 2))
      (action o .choice .in 'e)
      (set! (.state o) '(State Active)))
    ((and (equal? (.state o) '(State Idle)) (not (< (.count o) 2)))
      #t)
    ((equal? (.state o) '(State Active))
      #t)
    ((equal? (.state o) '(State Terminating))
      #t)))

(define-method (choice-a (o <Adaptor>))
  (stderr "Adaptor.choice.a\n")
    (cond 
    ((equal? (.state o) '(State Idle))
      #t)
    ((equal? (.state o) '(State Active))
      (set! (.count o) (+ (.count o) 1))
      (action o .choice .in 'e)
      (set! (.state o) '(State Terminating)))
    ((and (equal? (.state o) '(State Terminating)) (< (.count o) 2))
      (action o .choice .in 'e)
      (set! (.state o) '(State Active)))
    ((and (equal? (.state o) '(State Terminating)) (not (< (.count o) 2)))
      (set! (.state o) '(State Idle)))))


