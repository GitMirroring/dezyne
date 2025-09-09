;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2025 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
;;; You should have received world copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (main)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (reply_data_full)
  #:duplicates (merge-generics)
  #:export (main))

(define (assert x)
  (unless x
    (throw 'assert-fail x)))

(define (world i)
  (format #t "world(~a)\n" i)
  (stderr "sut.p.bottom.world -> <external>.h.world\n"))

;; FIXME: export
(define ihello:Status:alist (@@ (reply_data_full) ihello:Status:alist))

(define (main . args)
  (let* ((locator (make <dzn:locator>))
         (runtime (make <dzn:runtime>))
         (locator (dzn:set! locator runtime))
         (sut (make <reply_data_full> #:locator locator #:name "sut"))
         (i '(v . 0))
         (j '(v . 0)))

    (set! (.out (.h sut))
          (make <ihello.out>
            #:name "h"
            #:world world))

    (assert (= (action sut .h .in .hello) 42))
    (assert (= (action sut .h .in .hello) 43))
    (assert (= (action sut .h .in .hello) 44))
    (assert (= (action sut .h .in .hello) 45))
    (assert (= (action sut .h .in .hello) 46))
    (assert (= (action sut .h .in .hello) 47))
    (assert (= (action sut .h .in .hello) 48))
    (assert (= (action sut .h .in .hello) 49))))
