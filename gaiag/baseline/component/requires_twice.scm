;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; This file is part of Gaiag.
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

(define-class <requires_twice> (<component>)
  (p :accessor .p :init-form (make <interface:irequires_twice>))
  (once :accessor .once :init-form (make <interface:irequires_twice>))
  (twice :accessor .twice :init-form (make <interface:irequires_twice>)))

(define-method (initialize (o <requires_twice>) args)
  (next-method)
  (set! (.p o)
    (make <interface:irequires_twice>
      :in `((e . ,(lambda () (p-e o))))))
  (set! (.once o)
    (make <interface:irequires_twice>
      :out `((a . ,(lambda () (once-a o))))))
  (set! (.twice o)
    (make <interface:irequires_twice>
      :out `((a . ,(lambda () (twice-a o)))))))

(define-method (p-e (o <requires_twice>))
  (stderr "requires_twice.p.e\n")
    (action o .once .in 'e)
    (action o .twice .in 'e))

(define-method (once-a (o <requires_twice>))
  (stderr "requires_twice.once.a\n")
    #t)

(define-method (twice-a (o <requires_twice>))
  (stderr "requires_twice.twice.a\n")
    (action o .p .out 'a))


