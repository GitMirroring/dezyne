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

(define-class <Twotopon> (<component>)
  (b :accessor .b :init-value #f)
  (i :accessor .i :init-form (make <interface:ITwotopon>)))

(define-method (initialize (o <Twotopon>) args)
  (next-method)
  (set! (.i o)
    (make <interface:ITwotopon>
      :in `((e . ,(lambda () (i-e o)))
            (t . ,(lambda () (i-t o)))))))

(define-method (i-e (o <Twotopon>))
  (stderr "Twotopon.i.e\n")
    (cond 
    ((.b o)
      (action o .i .out 'a))
    ((not (.b o))
      (action o .i .out 'a))))

(define-method (i-t (o <Twotopon>))
  (stderr "Twotopon.i.t\n")
    (action o .i .out 'a))


