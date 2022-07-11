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
  #:use-module (blocking_release)
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
         (sut (make <blocking_release> #:locator locator #:name "sut"))
         (trace (string-trim-right (read-string)))
         (trace-alist
          `(("block.hello\nw.hello\nw.return\nrelease.hello\nw.hello\nw.return\nrelease.return\nrelease.hello\nrelease.return\nblock.return"
             . (,(cute action sut .block .in .hello)
                ,(lambda _
                   (action sut .release .in .hello)
                   (action sut .release .in .hello))))
            ("block.hello\nw.hello\nw.return\nrelease.hello\nw.hello\nw.return\nrelease.return\nblock.return"
             . (,(cute action sut .block .in .hello)
                 ,(cute action sut .release .in .hello)))
            ("block.hello\nw.hello\nw.return\nw.world\nblock.return"
             .
             (,(cute action sut .block .in .hello)
              ,(cute action sut .w .out .world)))
            ("release.hello\nrelease.return"
             .
             (,(lambda _
                 (action sut .release .in .hello)))))))

    (set! (.name (.out (.block sut))) "block")
    (set! (.name (.out (.release sut))) "release")
    (set! (.name (.in (.w sut))) "w")
    (set! (.hello (.in (.w sut))) (lambda _
                                    (dzn:trace log (.w sut) "hello")
                                    (dzn:trace-out log (.w sut) "return")))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cute dzn:pump pump <>) proc))
    (dzn:finalize pump)))
