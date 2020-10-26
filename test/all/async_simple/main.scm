;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (async_simple)
  #:duplicates (merge-generics)
  #:export (main))

(define (log-out prefix event)
  (stderr "<external>.~a~a <- sut.~a~a\n" prefix event prefix event)
  #f)

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <dzn:locator>))
         (runtime (make <dzn:runtime> #:illegal print-illegal))
         (pump (make <dzn:pump>))
         (locator (dzn:set! locator runtime))
         (locator (dzn:set! locator pump))
         (sut (make <async_simple> #:locator locator #:name "sut"))
         (trace (string-trim-right (read-string)))
         (trace-alist `(("p.c\np.return" . (,(lambda _ (action sut .p .in .c))))
                        ("p.e\np.return\np.c\np.return" . (,(lambda _
                                                              (action sut .p .in .e)
                                                              (action sut .p .in .c))))
                        ("p.e\np.return\np.cb" . (,(lambda _ (action sut .p .in .e)))))))

    (set! (.name (.out (.p sut))) "p")
    (set! (.cb (.out (.p sut))) (lambda _ (log-out "p." "cb")))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cut dzn:pump pump <>) proc))
    (dzn:finalize pump)))
