;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (S Foreign)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (foreign_namespace)
  #:export (<S:Foreign>
            .p))

(define-class <S:Foreign> (<dzn:component>)
  (reply-S-I-R #:accessor .reply-S-I-R #:init-value *unspecified*)
  (p #:accessor .p #:init-keyword #:p))

(define-method (initialize (o <S:Foreign>) args)
  (next-method)
  (set! (.p o)
        (make <S:I>
          #:in (make <S:I.in>
                 #:name 'p
                 #:self o
                 #:e (lambda args (call-in o (lambda _ (apply p-e (cons o args))) `(,(.p o) e)))#:f (lambda args (call-in o (lambda _ (apply p-f (cons o args))) `(,(.p o) f))))
          #:out (make <S:I.out>))))


(define-method (p-e (o <S:Foreign>))
  *unspecified*)

(define-method (p-f (o <S:Foreign>))
  (.reply-S:I-R o))
