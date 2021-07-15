;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2019, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2017, 2020 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
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

(define-module (dzn misc)
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (json)

  #:export (alist->hash-table
            conjoin
            disjoin
            hash-table->alist
            json-string->alist-scm
            merge-alist2
            merge-alist-list
            pke
            singleton?
            split-lists))

(define (disjoin . predicates)
  (lambda arguments
    (any (cut apply <> arguments) predicates)))

(define (conjoin . predicates)
  (lambda arguments
    (every (cut apply <> arguments) predicates)))

(define (singleton? list)
  (and (= 1 (length list)) (car list)))

(define (pke . stuff)
  "Like peek (pk), writing to (CURRENT-ERROR-PORT)."
  (newline (current-error-port))
  (display ";;; " (current-error-port))
  (write stuff (current-error-port))
  (newline (current-error-port))
  (car (last-pair stuff)))

(define (alist->hash-table alist)
  (let ((table (make-hash-table (length alist))))
    (for-each (lambda (entry)
                (let ((key (car entry))
                      (value (cdr entry)))
                  (hash-set! table key value)))
              alist)
    table))

(define (hash-table->alist table)
  (hash-map->list cons table))

(define (json-string->alist-scm src)
  "Compatibility between guile-json-1 (which produces hash-tables) and
guile-json-4 (which produces vectors)."
  (match src
    ((? hash-table?) (json-string->alist-scm (hash-table->alist src)))
    ((h ...) (map json-string->alist-scm src))
    ((h . t) (cons (json-string->alist-scm h) (json-string->alist-scm t)))
    (#(x ...) (json-string->alist-scm (vector->list src)))
    ((? string?) (if (or (string-prefix? "[" src)
                         (string-prefix? "{" src))
                     (catch #t (lambda _ (json-string->alist-scm (json-string->scm src))) (const src))
                     src))
    ("false" #f)
    ('false #f)
    ("true" #t)
    ('true #t)
    (_ src)))

(define (merge-alist2 a b)
  (fold
   (lambda (entry result)
     (match entry
       ((h t ...)
        (acons h
               (append t
                       (or (assoc-ref result h) '()))
               (alist-delete h result)))))
   a b))

(define (merge-alist-list alist-list)
  (match alist-list
    ((h t ...)
     (fold merge-alist2 h t))))

(define (split-lists split lists)
  (let loop ((lists lists) (heads '()) (tails '()))
    (if (null? lists) (values heads tails)
        (let* ((list (car lists))
               (head tail (split list)))
          (loop (cdr lists)
                (if (null? head) heads (cons head heads))
                (if (null? tail) tails (cons tail tails)))))))
