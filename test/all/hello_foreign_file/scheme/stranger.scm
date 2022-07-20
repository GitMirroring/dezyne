;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (stranger)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (iworld)
  #:export (<stranger>
            .w))

(define-class <stranger> (<dzn:component>)
  (w #:accessor .w #:init-keyword #:w))

(define-method (initialize (o <stranger>) args)
  (next-method)
  (set! (.w o)
        (make <iworld>
          #:in (make <iworld.in>
                 #:name "w"
                 #:self o
                 #:world (lambda args (call-in o (lambda _ (apply w-world (cons o args))) `(,(.w o) "world"))))
          #:out (make <iworld.out>))))

(define-method (w-world (o <stranger>))
  *unspecified*)
