;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (rnrs base)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 rdelim)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (dzn pump)
  #:use-module (defer_data)
  #:duplicates (merge-generics)
  #:export (main))

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <dzn:locator>))
         (runtime (make <dzn:runtime> #:illegal print-illegal))
         (pump (make <dzn:pump>))
         (locator (dzn:set! locator runtime))
         (locator (dzn:set! locator pump))
         (log (dzn:get locator <procedure> 'trace))
         (sut (make <defer_data> #:locator locator #:name "sut"))
         (trace (string-trim-right (read-string)))
         (trace-alist
          `(("h.hello\nh.return\nh.hi\nh.return\n<defer>\nh.world"
             . (,(cute action sut .h .in .hello 0)
                ,(cute action sut .h .in .hi 0)))
            ("h.hello\nh.return\nh.cruel\nh.return\n<defer>\nh.world"
             . (,(cute action sut .h .in .hello 0)
                ,(cute action sut .h .in .cruel 1))))))

    (set! (.name (.out (.h sut))) "h")
    (set! (.world (.out (.h sut))) (lambda _ (dzn:trace log (.h sut) "world")))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cute dzn:pump pump <>) proc))
    (dzn:finalize pump)))
