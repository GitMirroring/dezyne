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

(define-class <Guardthreetopon> (<component>)
  (b :accessor .b :init-value #f)
  (i :accessor .i :init-form (make <interface:IGuardthreetopon>))
  (r :accessor .r :init-form (make <interface:RGuardthreetopon>)))

(define-method (initialize (o <Guardthreetopon>) args)
  (next-method)
  (set! (.i o)
    (make <interface:IGuardthreetopon>
      :in `((e . ,(lambda () (i-e o)))
            (t . ,(lambda () (i-t o)))
            (s . ,(lambda () (i-s o))))))
  (set! (.r o)
    (make <interface:RGuardthreetopon>
      :out `((a . ,(lambda () (r-a o)))))))

(define-method (i-e (o <Guardthreetopon>))
  (stderr "Guardthreetopon.i.e\n")
    (cond 
    ((and #t (.b o))
      (action o .i .out 'a))
    ((and #t (not (.b o)))
      (let ((c #t)) 
      (cond (c 
        (action o .i .out 'a)))))))

(define-method (i-t (o <Guardthreetopon>))
  (stderr "Guardthreetopon.i.t\n")
    (cond 
    ((.b o)
      (action o .i .out 'a))
    ((not (.b o))
      (action o .i .out 'a))))

(define-method (i-s (o <Guardthreetopon>))
  (stderr "Guardthreetopon.i.s\n")
    (action o .i .out 'a))

(define-method (r-a (o <Guardthreetopon>))
  (stderr "Guardthreetopon.r.a\n")
    #t)


