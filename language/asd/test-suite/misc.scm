;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2013, 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (test-suite misc)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 regex)

  :use-module (language asd misc)
  :export (fail
           diff-noisy-equal?
	   noisy-equal?
           pretty-noisy-equal?
           whitespace-noisy-equal?)
  :re-export (hash-read-string))

(define (fail string . rest)
  (apply stderr (cons* string rest))
  #f)

(define (noisy-equal? a b)
  (or (equal? a b)
      (fail "~a\n!=\n~a\n" a b)))

(define (pretty-noisy-equal? a b)
  (or (equal? a b)
      (fail "~a!=\n~a" (pretty-string a) (pretty-string b))))

(define (collapse-whitespace string)
  (string-trim
   (string-sub " +" " "
               (string-sub "\n+" "\n"
                           (string-sub "\n +" "\n"
                                       (string-sub " +\n" "\n" string))))))

(define (whitespace-noisy-equal? a b)
  (let ((wa (collapse-whitespace a))
        (wb (collapse-whitespace b)))
    (or (equal? wa wb)
        (fail "~a!=\n~a" wa wb))))

(define (diff-noisy-equal? a b)
  (let ((diff (diff (collapse-whitespace a) 
                    (collapse-whitespace b)
                    "-u"
                    "actual"
                    "expected")))
    (or (string-null? diff)
        (fail "~a" diff))))

(read-hash-extend #\{ hash-read-string)
