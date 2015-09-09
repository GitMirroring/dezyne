;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag coroutine)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)

  :use-module (gaiag misc)
  :export (coroutine))

(define-syntax-rule (let/cc var body ...)
  (call/cc (lambda (var) body ...)))

(define-syntax-rule (yield-cc+data cc+data data item)
  (begin
    (set! cc+data (let/cc cc ((car cc+data) (cons cc item))))
    (set! data (cdr cc+data))))

(define (producer name work)
  (lambda (yield data)
    (let loop ((todo work))
      (if (null? todo)
          'done
          (let ((item (car todo)))
            (stderr "~a[~a] ==> ~a\n" name item (data))
            (yield item)
            (loop (cdr todo)))))))

(define* (coroutine routine :optional (start 'start))
  (lambda (cc+data)
    (or (pair? cc+data) (set! cc+data (cons cc+data start)))
    (letrec ((data (lambda () (cdr cc+data)))
             (yield (lambda (item) (yield-cc+data cc+data data item))))
      (routine yield data))))

(define (consumer yield data)
  (while #t
    (stderr "  consumer: ~a\n" (data))
    (yield #f)))

(define (ast-> ast)
  ((coroutine (producer 'producer '(a b c))) (coroutine (producer "  consumer" '(0 1 2 3 4 5))))
  (stderr "\n\n")
  ((coroutine (producer 'producer '(a b c))) (coroutine consumer)))
