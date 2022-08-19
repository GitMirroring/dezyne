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
            .h
            .w0
            .w1
            w0-world
            w1-world))

(define-class <Foreign> (<dzn:component>)
  (out_h #:accessor .out_h #:init-value #f #:init-keyword #:out_h)
  (h #:accessor .h #:init-form (make <ihello>) #:init-keyword #:h)
  (w0 #:accessor .w0 #:init-form (make <ihello>) #:init-keyword #:w0)
  (w1 #:accessor .w1 #:init-form (make <ihello>) #:init-keyword #:w1))

(define-method (initialize (o <Foreign>) args)
  (next-method o (cons* #:flushes? #t args))
  (set! (.h o)
        (make <ihello>
          #:in (make <ihello.in>
                 #:name "h"
                 #:self o
                 #:hello
                 (lambda args
                   (call-in o
                            (lambda _
                              (apply h-hello (cons o args)))
                            `(,(.h o) "hello"))))
          #:out (make <ihello.out>)))
  (set! (.w0 o)
        (make <ihello>
          #:in (make <ihello.in>)
          #:out (make <ihello.out>
                  #:name "w0"
                  #:self o
                  #:world
                  (lambda args
                    (call-out o
                              (lambda _
                                (apply w0-world (cons o args)))
                              `(,(.w0 o) "world"))))))
  (set! (.w1 o)
        (make <ihello>
          #:in (make <ihello.in>)
          #:out (make <ihello.out>
                  #:name "w1"
                  #:self o
                  #:world
                  (lambda args
                    (call-out o
                              (lambda _
                                (apply w1-world (cons o args)))
                              `(,(.w1 o) "world")))))))

(define-method (h-hello (o <Foreign>))
  *unspecified*)

(define-method (w0-world (o <Foreign>))
  (action o .w0 .in .hello))

(define-method (w1-world (o <Foreign>))
  (action o .w1 .in .hello))
