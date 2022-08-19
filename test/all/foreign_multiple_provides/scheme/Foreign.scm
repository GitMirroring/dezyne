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

(define-module (Foreign)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (ihello)
  #:duplicates (merge-generics)
  #:export (<Foreign>
            .h0
            .h1))

(define-class <Foreign> (<dzn:component>)
  (h0 #:accessor .h0 #:init-keyword #:h0)
  (h1 #:accessor .h1 #:init-keyword #:h1))

(define-method (initialize (o <Foreign>) args)
  (next-method o (cons* #:flushes? #t args))
  (set! (.h0 o)
        (make <ihello>
          #:in (make <ihello.in>
                 #:name "h0"
                 #:self o
                 #:hello
                 (lambda args
                   (call-in o
                            (lambda _
                              (apply h0-hello (cons o args)))
                            `(,(.h0 o) "hello"))))
          #:out (make <ihello.out>)))
  (set! (.h1 o)
        (make <ihello>
          #:in (make <ihello.in>
                 #:name "h1"
                 #:self o
                 #:hello
                 (lambda args
                   (call-in o
                            (lambda _
                              (apply h1-hello (cons o args)))
                            `(,(.h1 o) "hello"))))
          #:out (make <ihello.out>))))

(define-method (h0-hello (o <Foreign>))
  (action o .h0 .out .world))

(define-method (h1-hello (o <Foreign>))
  (action o .h1 .out .world))
