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

(define-class <Topon> (<component>)
  (b :accessor .b :init-value #f)
  (c :accessor .c :init-value #f)
  (i :accessor .i :init-form (make <interface:ITopon>)))

(define-method (initialize (o <Topon>) args)
  (next-method)
  (set! (.i o)
    (make <interface:ITopon>
      :in `((e . ,(lambda () (i-e o)))
            (t . ,(lambda () (i-t o)))))))

(define-method (i-e (o <Topon>))
  (stderr "Topon.i.e\n")
    (cond 
    ((and (.b o) (not (.c o)))
      (action o .i .out 'a))
    ((and (not (.b o)) (not (.c o)))
      (action o .i .out 'a))
    ((and (not (.c o)) (not (.b o)))
      (action o .i .out 'a))))

(define-method (i-t (o <Topon>))
  (stderr "Topon.i.t\n")
    (action o .i .out 'a))


