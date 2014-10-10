;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <enum_collision> (<component>)
  (reply-ienum_collision-Retval1 :accessor .reply-ienum_collision-Retval1 :init-value #f)
  (reply-ienum_collision-Retval2 :accessor .reply-ienum_collision-Retval2 :init-value #f)
  (i :accessor .i :init-form (make <interface:ienum_collision>)))

(define-method (initialize (o <enum_collision>) args)
  (next-method)
  (set! (.i o)
    (make <interface:ienum_collision>
      :in `((foo . ,(lambda () (i-foo o)))
            (bar . ,(lambda () (i-bar o)))))))

(define-method (i-foo (o <enum_collision>))
  (stderr "enum_collision.i.foo\n")
    (set! (.reply-ienum_collision-Retval1 o) '(Retval1 OK))
    (.reply-ienum_collision-Retval1 o))

(define-method (i-bar (o <enum_collision>))
  (stderr "enum_collision.i.bar\n")
    (set! (.reply-ienum_collision-Retval2 o) '(Retval2 NOK))
    (.reply-ienum_collision-Retval2 o))


