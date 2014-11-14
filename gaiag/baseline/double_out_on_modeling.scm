;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <double_out_on_modeling> (<component>)
  (state :accessor .state :init-value '(State First))
  (p :accessor .p :init-form (make <interface:I>))
  (r :accessor .r :init-form (make <interface:I>)))

(define-method (initialize (o <double_out_on_modeling>) args)
  (next-method)
  (set! (.p o)
    (make <interface:I>
      :in `((start . ,(lambda () (p-start o))))))
  (set! (.r o)
    (make <interface:I>
      :out `((foo . ,(lambda () (r-foo o)))
            (bar . ,(lambda () (r-bar o)))))))

(define-method (p-start (o <double_out_on_modeling>))
  (stderr "double_out_on_modeling.p.start\n")
    (cond 
    ((equal? (.state o) '(State First))
      (action o .r .in 'start)
      (set! (.state o) '(State Second)))
    ((equal? (.state o) '(State Second))
      (illegal))))

(define-method (r-foo (o <double_out_on_modeling>))
  (stderr "double_out_on_modeling.r.foo\n")
    (cond 
    ((equal? (.state o) '(State First))
      (illegal))
    ((equal? (.state o) '(State Second))
      (action o .p .out 'foo))))

(define-method (r-bar (o <double_out_on_modeling>))
  (stderr "double_out_on_modeling.r.bar\n")
    (cond 
    ((equal? (.state o) '(State First))
      (illegal))
    ((equal? (.state o) '(State Second))
      (action o .p .out 'bar)
      (set! (.state o) '(State First)))))


