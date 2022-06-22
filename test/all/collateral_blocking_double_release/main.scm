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

(define-module (main)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 rdelim)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (dzn pump)
  #:use-module (collateral_blocking_double_release)
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
         (sut (make <collateral_blocking_double_release> #:locator locator #:name "sut"))
         (trace (string-trim-right (read-string)))
         (trace-alist
          `(("block1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.hello\nw.hello\nw.return\nblock1.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return"
             . (,(lambda _
                   (action sut .block1 .in .hello)
                   (action sut .release .in .hello))
                ,(lambda _
                   (action sut .release .in .hello)
                   (action sut .block0 .in .hello))))
            ("block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nw.world\nw.cruel\nw.return\nblock0.return\nblock1.return"
             . (,(cute action sut .block0 .in .hello)
                ,(cute action sut .block1 .in .hello)
                ,(cute action sut .w .out .world)))
            ("block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return\nblock1.return"
             .
             (,(cute action sut .block0 .in .hello)
              ,(cute action sut .block1 .in .hello)
              ,(cute action sut .release .in .hello))))))

    (set! (.name (.out (.block0 sut))) "block0")
    (set! (.name (.out (.block1 sut))) "block1")
    (set! (.name (.out (.release sut))) "release")
    (set! (.name (.in (.w sut))) "w")
    (set! (.hello (.in (.w sut))) (lambda _
                                    (dzn:trace log (.w sut) "hello")
                                    (dzn:trace-out log (.w sut) "return")))
    (set! (.cruel (.in (.w sut))) (lambda _
                                    (dzn:trace log (.w sut) "cruel")
                                    (dzn:trace-out log (.w sut) "return")))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cute dzn:pump pump <>) proc))
    (dzn:finalize pump)))
