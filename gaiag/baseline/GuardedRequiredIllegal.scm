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

(define-class <GuardedRequiredIllegal> (<component>)
  (c :accessor .c :init-value #f)
  (t :accessor .t :init-form (make <interface:Top>))
  (b :accessor .b :init-form (make <interface:Bottom>)))

(define-method (initialize (o <GuardedRequiredIllegal>) args)
  (next-method)
  (set! (.t o)
    (make <interface:Top>
      :in `((unguarded . ,(lambda () (t-unguarded o)))
            (e . ,(lambda () (t-e o))))))
  (set! (.b o)
    (make <interface:Bottom>
      :out `((f . ,(lambda () (b-f o)))))))

(define-method (t-unguarded (o <GuardedRequiredIllegal>))
  (stderr "GuardedRequiredIllegal.t.unguarded\n")
    #t)

(define-method (t-e (o <GuardedRequiredIllegal>))
  (stderr "GuardedRequiredIllegal.t.e\n")
    (cond 
    ((not (.c o))
      (set! (.c o) #t)
      (action o .b .in 'e))
    ((.c o)
      #t)))

(define-method (b-f (o <GuardedRequiredIllegal>))
  (stderr "GuardedRequiredIllegal.b.f\n")
    (cond 
    ((not (.c o))
      (illegal))
    ((.c o)
      (set! (.c o) #f))))


