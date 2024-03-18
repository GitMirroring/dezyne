;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2019, 2021, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (main)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (ihelloworld)
  #:use-module (helloworld)
  #:use-module (hello_injected)
  #:duplicates (merge-generics)
  #:export (main))

(define (main . args)
  (let* ((locator (make <dzn:locator>))
         (runtime (make <dzn:runtime>))
         (locator (dzn:set! locator runtime))
         (sut (make <hello_injected> #:locator locator #:name "sut")))

    (set! (.name (.out (.h sut))) "h")
    (set! (.out (.h sut))
          (make <ihelloworld.out>
            #:name "h"
            #:world (lambda _ (format (current-error-port) "sut.m.h.world -> <external>.h.world\n"))))

    (action sut .h .in .hello)))
