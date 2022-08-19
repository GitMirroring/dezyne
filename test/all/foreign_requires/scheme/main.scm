;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (srfi srfi-26)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (foreign_requires)
  #:use-module (Foreign)
  #:duplicates (merge-generics)
  #:export (main))

(define (main . args)
  (let* ((print-illegal (lambda () (format (current-error-port) "illegal\n") (exit 1)))
         (locator (make <dzn:locator>))
         (runtime (make <dzn:runtime> #:illegal print-illegal))
         (locator (dzn:set! locator runtime))
         (sut (make <foreign_requires> #:locator locator #:name "sut")))
    (set! (.hello (.in (.w0 (.c sut))))
          (lambda _
            (display  "<external>.w0.hello -> sut.c.w0.hello\n" (current-error-port))
            (display  "<external>.w0.return <- sut.c.w0.return\n" (current-error-port))))
    (set! (.hello (.in (.w1 (.c sut))))
          (lambda _
            (display  "<external>.w1.hello -> sut.c.w1.hello\n" (current-error-port))
            (display  "<external>.w1.return <- sut.c.w1.return\n" (current-error-port))))
    (w0-world (.f sut))
    (w1-world (.f sut))))
