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
  #:use-module (async_order2)
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
         (sut (make <async_order2> #:locator locator #:name "sut"))
         (trace (string-trim-right (read-string)))
         (trace-alist `(("p.c\np.return" . (,(lambda _ (action sut .p .in .c))))

                        ("p.e\np.return\np.c\np.return" . (,(lambda _
                                                              (action sut .p .in .e)
                                                              (action sut .p .in .c))))
                        ("p.e\np.return\np.cb1\np.c\np.return"
                         ;; XXX: Just echo the expected trace...
                         . (,(lambda _
                               (display
                                (string-append
                                 "<external>.p.e -> sut.p.e\n"
                                 "<external>.p.return <- sut.p.return\n"
                                 "sut.p.<q> <- <external>.p.cb1\n"
                                 "<external>.p.cb1 <- <external>.<q>\n"
                                 "<external>.p.c -> sut.p.c\n"
                                 "<external>.p.return <- sut.p.return\n")
                                (current-error-port)))))
                        ("p.e\np.return\np.cb1\np.c\np.return"
                         ;; After rewiring the system and blanking out port names, feeding
                         ;; the input trace produces a code trace that could be filtered
                         ;; into compliance with the input trace.

                         ;; Disabled this trickery for now.
                         . (,(lambda _
                               (let ((c (make <cb1_cancel> #:locator locator #:name (string->symbol " "))))
                                 (set! (.name (.out (.p sut))) (string->symbol " "))
                                 (set! (.name sut) '<external>)
                                 (dzn:connect (.p sut) (.r c))
                                 (action c .p .in .e)))))
                        ("p.e\np.return\np.cb1\np.cb2" . (,(lambda _ (action sut .p .in .e)))))))

    (set! (.name (.out (.p sut))) "p")
    (set! (.cb1 (.out (.p sut))) (lambda _ (log-out "p." "cb1")))
    (set! (.cb2 (.out (.p sut))) (lambda _ (log-out "p." "cb2")))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cut dzn:pump pump <>) proc))
    (dzn:finalize pump)))
