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
  #:use-module (async_prio2)
  #:duplicates (merge-generics)
  #:export (main))

(define (consume-synchronous-out-events prefix event event-alist)
  (let ((match (symbol-append prefix event)))
    (let loop ((s (read-line)))
      (and s
           (not (eof-object? s))
           (not (eq? (string->symbol s) match))
           (loop (read-line)))))
  (let loop ((s (read-line)))
    (let ((event (and s
                      (not (eof-object? s))
                      (assoc-ref event-alist (string->symbol s)))))
      (if (not event) (and s (not (eof-object? s)) (last (string-split s #\.)))
          (begin (event)
                 (loop (read-line)))))))

(define (log-in prefix event event-alist)
  (stderr "<external>.~a~a -> sut.~a~a\n" prefix event prefix event)
  (consume-synchronous-out-events prefix event event-alist)
  (stderr "<external>.~a~a -> sut.~a~a\n" prefix 'return prefix 'return))

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
         (sut (make <async_prio2> #:locator locator #:name 'sut))
         (trace (string-trim-right (read-string)))
         (event-alist `((p.e . ,(lambda _ (apply (.e (.in (.p sut))) (list))))
                        (p.c . ,(lambda _ (apply (.c (.in (.p sut))) (list))))
                        (r.cb . ,(lambda _ (apply (.cb (.out (.r sut))) (list))))
                        (i.ack . ,(lambda _ (apply (.ack (.out (.i sut))) (list))))
                        (r.<flush> . ,(lambda _ (stderr "r.<flush>\n") (dzn:flush (.self (.in (.r sut))))))))
         (trace-alist `(("p.c\np.return" . (,(lambda _ (action sut .p .in .c))))
                        ("p.e\np.return\np.c\nr.c\nr.return\np.return"
                         . (,(lambda _
                               (action sut .p .in .e)
                               (action sut .p .in .c))))
                        ("p.e\np.return\nr.e\nr.return\np.c\nr.c\nr.return\np.return"
                         . (,(lambda _ (action sut .p .in .e))
                            ,(lambda _ (action sut .p .in .c))))
                        ("p.e\np.return\nr.e\nr.return\nr.cb\np.cb"
                         . (,(lambda _ (action sut .p .in .e))
                            ,(lambda _ (action sut .r .out .cb)))))))

    (set! (.name (.out (.p sut))) 'p)
    (set! (.cb (.out (.p sut))) (lambda _ (log-out 'p. 'cb)))

    (set! (.name (.in (.r sut))) 'r)
    (set! (.e (.in (.r sut))) (lambda _ (log-in 'r. 'e event-alist)))
    (set! (.c (.in (.r sut))) (lambda _ (log-in 'r. 'c event-alist)))

    (let ((proc (assoc-ref trace-alist trace)))
      (unless proc
        (stderr "invalid trace: ~s\n" trace)
        (exit 1))
      (for-each (cut dzn:pump pump <>) proc))
    (dzn:finalize pump)))
