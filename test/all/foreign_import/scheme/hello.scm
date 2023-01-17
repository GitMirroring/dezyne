;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (hello)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (hello_foreign)
  #:duplicates (merge-generics)
  #:export (<hello>
            .h))

(define-class <hello> (<dzn:component>)
  (h #:accessor .h #:init-keyword #:h))

(define-method (initialize (o <hello>) args)
  (next-method)
  (set! (.h o)
        (make <ihello>
          #:in (make <ihello.in>
                 #:name "h"
                 #:self o
                 #:hello (lambda args
                           (call-in o
                                    (lambda _
                                      (apply h-hello (cons o args)))
                                    `(,(.h o) "hello"))))
          #:out (make <ihello.out>))))

(define-method (h-hello (o <hello>))
  *unspecified*)
