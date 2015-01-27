;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-class <Choice> (<component>)
  (s :accessor .s :init-value '(State Off))
  (c :accessor .c :init-form (make <interface:IChoice>)))

(define-method (initialize (o <Choice>) args)
  (next-method)
  (set! (.c o)
    (make <interface:IChoice>
      :in `((e . ,(lambda () (c-e o)))))))

(define-method (c-e (o <Choice>))
  (stderr "Choice.c.e\n")
    (cond 
    ((equal? (.s o) '(State Off))
      (set! (.s o) '(State Idle))
      (action o .c .out 'a))
    ((equal? (.s o) '(State Idle))
      (set! (.s o) '(State Busy))
      (action o .c .out 'a))
    ((equal? (.s o) '(State Busy))
      (set! (.s o) '(State Idle))
      (action o .c .out 'a))))


