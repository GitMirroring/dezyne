;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-class <modeling> (<component>)
  (p :accessor .p :init-form (make <interface:dummy>))
  (r :accessor .r :init-form (make <interface:imodeling>)))

(define-method (initialize (o <modeling>) args)
  (next-method)
  (set! (.p o)
    (make <interface:dummy>
      :in `((e . ,(lambda () (p-e o))))))
  (set! (.r o)
    (make <interface:imodeling>
      :out `((f . ,(lambda () (r-f o)))))))

(define-method (p-e (o <modeling>))
  (stderr "modeling.p.e\n")
    (action o .r .in 'e))

(define-method (r-f (o <modeling>))
  (stderr "modeling.r.f\n")
    #t)


