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

  :use-module (oop goops)
  :use-module (language asd gom)
  :use-module (language asd csp)

  :export (fail
           diff-noisy-equal?
	   noisy-equal?
           pretty-noisy-equal?
           whitespace-noisy-equal?)
  :re-export (hash-read-string))

(define (fail string . rest)
  (apply stderr (cons* string rest))
  #f)

;;(define equal? equal?)
;(define-generic equal?)
(define-method (xequal? (lhs <ast>) (rhs <ast>))
  (equal? (with-output-to-string (lambda () (write lhs)))
          (with-output-to-string (lambda () (write rhs)))))

(define (csp->gom* ast)
  ((compose ast->gom* csp->sugar ast->sugar) ast))

(define plain-equal? equal?)
(define (equal? actual expected)
  (plain-equal?
       (with-input-from-string
              (with-output-to-string (lambda ()
                                       (write (csp->gom* actual))))
            read)
          (with-input-from-string
              (with-output-to-string (lambda ()
                                       (write (csp->gom* expected))))
            read)))

(define (noisy-equal? actual expected)
  (or (equal? actual expected)
      (fail "~a\n!=\n~a\n" expected actual)))

(define (pretty-noisy-equal? actual expected)
  (or (equal? actual expected)
      (fail "~a!=\n~a" (pretty-string expected) (pretty-string actual))))

(define (collapse-whitespace string)
  (string-trim
   (string-sub " +" " "
               (string-sub "\n+" "\n"
                           (string-sub "\n +" "\n"
                                       (string-sub " +\n" "\n" string))))))

(define (whitespace-noisy-equal? actual expected)
  (let ((wexpected (collapse-whitespace expected))
        (wactual (collapse-whitespace actual)))
    (or (equal? wactual wexpected)
        (fail "~a!=\n~a" wexpected wactual))))

(define (diff-noisy-equal? actual expected)
  (let ((diff (diff (collapse-whitespace expected)
                    (collapse-whitespace actual)
                    "-u"
                    "expected"
                    "actual")))
    (or (string-null? diff)
        (fail "~a" diff))))

(read-hash-extend #\{ hash-read-string)
