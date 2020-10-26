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

(define-module (library foreign)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (library hello)
  #:duplicates (merge-generics)
  #:export (
    <library:foreign>
    w-world)
  #:re-export (.w))

(define-class <library:foreign> (<dzn:component>)
  (out_w #:accessor .out_w #:init-value #f #:init-keyword #:out_w)
  (w #:accessor .w #:init-form (make <library:iworld>) #:init-keyword #:w))

(define-method (initialize (o <library:foreign>) args)
  (next-method)
  (set! (.w o)
    (make <library:iworld>
      #:in (make <library:iworld.in>
        #:name "w"
        #:self o
        #:world (lambda args (call-in o (lambda _ (apply w-world (cons o args))) `(,(.w o) "world"))))
      #:out (make <library:iworld.out>))))

(define-method (w-world (o <library:foreign>))
  #t)
