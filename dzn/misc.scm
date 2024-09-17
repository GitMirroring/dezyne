;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2019, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2017, 2020, 2024 Rutger van Beusekom <rutger@dezyne.org>
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
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (json)

  #:export (->
            <->
            %debug?
            alist->hash-table
            atom?
            common-prefix
            conjoin
            debug
            delete-adjacent-duplicates
            disjoin
            display-join
            display-join*
            hash-table->alist
            json-string->alist-scm
            merge-alist2
            merge-alist-list
            pke
            seq
            singleton?
            split-lists
            write-line-error)
  #:re-export (write-line))

(define (disjoin . predicates)
  "Like OR but for predicates:
  (filter (disjoin zero? odd?) '(0 1 2 3))
 => '(0 1 3)
"
  (lambda arguments
    (any (cut apply <> arguments) predicates)))

(define (conjoin . predicates)
  "Like AND but for predicates:
  (find (conjoin even? (negate zero?)) '(0 1 2 3))
 => '2
"
  (lambda arguments
    (every (cut apply <> arguments) predicates)))

(define (-> P Q)
  "Logical implication or conditional statement"
  (disjoin (negate P) Q))

(define (<-> P Q)
  "Bi-implication or biderectional statement"
  (disjoin (conjoin P Q)
           (negate (disjoin P Q))))

(define (seq . procedures)
  "Like COMPOSE but for PROCEDURES running in sequence on the same
arguments:
  (append-map (seq (cute 1+ <>) (cute * 3 <>)) '(0 1 2 ))
 => (2 2 3 4 4 6)
"
  (lambda arguments
    (map (cute apply <> arguments) procedures)))

(define (atom? o)
  (and (not (pair? o))
       (not (null? o))))

(define (singleton? list)
  (and (= 1 (length list)) (car list)))

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

(define* (display-join* lst #:key
                        (port (current-output-port))
                        (display-element (cute display <> <>))
                        (grammar '()))
  "Like STRING-JOIN but displaying to PORT, also allowing \"PRE\" 'pre
and \"POST\" 'post in GRAMMAR."
  (define (reduce-sexp l)
    (unfold null? (compose (cute apply list <>) (cute list-head <> 2)) cddr l))

  (define (xassq key alist)
    (find (compose (cute eq? <> key) cadr) alist))

  (define (xassq-ref alist key)
    (and=> (xassq key alist) car))

  (let* ((grammar-alist (match grammar
                          (((and (? string?) str)) `((,str infix)))
                          (_ (reduce-sexp grammar))))
         (infix (xassq-ref grammar-alist 'infix))
         (suffix (xassq-ref grammar-alist 'suffix))
         (prefix (xassq-ref grammar-alist 'prefix))
         (pre (xassq-ref grammar-alist 'pre))
         (post (xassq-ref grammar-alist 'post)))
    (when (and pre (pair? lst))
      (display pre port))
    (let loop ((lst lst))
      (when (pair? lst)
        (when prefix
          (display prefix port))
        (display-element (car lst) port)
        (when suffix
          (display suffix port))
        (when (and (pair? (cdr lst)) infix)
          (display infix port))
        (loop (cdr lst))))
    (when (and post (pair? lst))
      (display post port))))

(define (display-join lst port . grammar)
  (display-join* lst #:port port #:grammar grammar))

(define (delete-adjacent-duplicates lst =)
  "When LST is sorted all duplicates are adjacent one another.
This procedure recursively drops an element from the list when it equals
the next element."
  (let loop ((lst lst))
    (match lst
      (() lst)
      ((head) lst)
      ((head next . rest)
       (let ((tail (cons next rest)))
         (if (= head next) (loop tail)
             (cons head (loop tail))))))))

(define* (common-prefix lst-a lst-b #:key (eq? eq?))
  (if (or (null? lst-a) (null? lst-b)) '()
      (let ((car-a lst-a (car+cdr lst-a))
            (car-b lst-b (car+cdr lst-b)))
        (if (not (eq? car-a car-b)) '()
            (cons car-a (common-prefix lst-a lst-b #:eq? eq?))))))


;;;
;;; Debugging.
;;;

;; Should debug info be printed?
(define %debug? (make-parameter #f))

(define (pke . stuff)
  "Like peek (pk), writing to (CURRENT-ERROR-PORT)."
  (newline (current-error-port))
  (display ";;; " (current-error-port))
  (write stuff (current-error-port))
  (newline (current-error-port))
  (car (last-pair stuff)))

(define (debug fmt . args)
  (when (%debug?)
    (apply format (current-error-port) fmt args)
    (newline (current-error-port))))

(define (write-line-error o)
  (write-line o (current-error-port)))
