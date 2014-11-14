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

(define-class <imperative> (<component>)
  (state :accessor .state :init-value '(States I))
  (i :accessor .i :init-form (make <interface:iimperative>)))

(define-method (initialize (o <imperative>) args)
  (next-method)
  (set! (.i o)
    (make <interface:iimperative>
      :in `((e . ,(lambda () (i-e o)))))))

(define-method (i-e (o <imperative>))
  (stderr "imperative.i.e\n")
    (cond 
    ((equal? (.state o) '(States I))
      (action o .i .out 'f)
      (action o .i .out 'g)
      (action o .i .out 'h)
      (set! (.state o) '(States II)))
    ((equal? (.state o) '(States II))
      (set! (.state o) '(States III)))
    ((equal? (.state o) '(States III))
      (action o .i .out 'f)
      (action o .i .out 'g)
      (action o .i .out 'g)
      (action o .i .out 'f)
      (set! (.state o) '(States IV)))
    ((equal? (.state o) '(States IV))
      (action o .i .out 'h)
      (set! (.state o) '(States I)))))


