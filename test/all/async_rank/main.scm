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
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 rdelim)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:use-module (dzn pump)
  #:use-module (async_rank)
  #:duplicates (merge-generics)
  #:export (main))

(define (log-out prefix event)
  (stderr "<external>.~a~a <- sut.~a~a\n" prefix event prefix event)
  #f)

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

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <dzn:locator>))
         (runtime (make <dzn:runtime> #:illegal print-illegal))
         (pump (make <dzn:pump>))
         (locator (dzn:set! locator runtime))
         (locator (dzn:set! locator pump))
         (sut (make <async_rank> #:locator locator #:name 'sut))
         (event-alist `((p.e . ,(lambda _ (apply (.e (.in (.p o))) (list))))
                        (r.f . ,(lambda _ (apply (.f (.out (.r o))) (list))))
                        (r.g . ,(lambda _ (apply (.g (.out (.r o))) (list))))
                        (r.<flush> . ,(lambda _ (stderr "r.<flush>\n") (dzn:flush (.self (.in (.r o)))))))))

    (set! (.name (.out (.p sut))) 'p)
    (set! (.f (.out (.p sut))) (lambda _ (log-out 'p. 'f)))
    (set! (.g (.out (.p sut))) (lambda _ (log-out 'p. 'g)))

    (set! (.name (.in (.r sut))) 'r)
    (set! (.e (.in (.r sut))) (lambda _ (log-in 'r. 'e event-alist)))

    (dzn:pump pump (lambda _ (action sut .p .in .e)))
    (dzn:pump pump (lambda _ (action sut .r .out .f)))
    (dzn:pump pump (lambda _ (action sut .r .out .g)))
    (dzn:finalize pump)))
