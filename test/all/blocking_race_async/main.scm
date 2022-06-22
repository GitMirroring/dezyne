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
  #:use-module (blocking_race_async)
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
         (sut (make <blocking_race_async> #:locator locator #:name "sut"))
         (complete? #t)
         (trace (string-trim-right (read-string)))
         (trace-alist
          `(("pt.cancel\nrt.cancel\nrt.return\npt.return"
             . (,(cute action sut .pt .in .cancel)))
            ("pt.request\nrt.request\nrt.return\nrb.block\nrt.complete\nrb.return\nrt.cancel\nrt.return\npt.return\npt.cancel\nrt.cancel\nrt.return\npt.return"
             . (,(lambda _
                   (action sut .pt .in .request)
                   (action sut .pt .in .cancel))))
            ("pt.request\nrt.request\nrt.return\nrb.block\nrt.complete\nrb.return\nrt.cancel\nrt.return\npt.return\npt.complete"
             .
             (,(cute action sut .pt .in .request)))
            ("pt.request\nrt.request\nrt.return\nrb.block\nrb.return\nrt.cancel\nrt.return\npt.return\npt.cancel\nrt.cancel\nrt.return\npt.return"
             .
             (,(lambda _
                 (set! complete? #f)
                 (action sut .pt .in .request))
              ,(cute action sut .pt .in .cancel))))))

    (set! (.name (.out (.pt sut))) "pt")
    (set! (.name (.in (.rb sut))) "rb")
    (set! (.name (.in (.rt sut))) "rt")
    (set! (.complete (.out (.pt sut)))
          (lambda _
            (dzn:trace log (.pt sut) "complete")))
    (set! (.block (.in (.rb sut)))
          (lambda _
            (dzn:trace log (.rb sut) "block")
            (when complete?
              (action sut .rt .out .complete))
            (dzn:trace-out log (.rb sut) "return")))
    (set! (.request (.in (.rt sut)))
          (lambda _
            (dzn:trace log (.rt sut) "request")
            (dzn:trace-out log (.rt sut) "return")))
    (set! (.cancel (.in (.rt sut)))
          (lambda _
            (dzn:trace log (.rt sut) "cancel")
            (dzn:trace-out log (.rt sut) "return")))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cute dzn:pump pump <>) proc))
    (dzn:finalize pump)))
