;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (language asd misc)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 rdelim)
  :use-module (ice-9 regex)

  :use-module (os process)
  :use-module (srfi srfi-1)
  :use-module (rnrs io ports)

  :use-module (language asd fifo)
  :export (
           *eof*
           *eof*-is-#f
           ->join
           ->string
           =0
           =1
           =2
           >0
           >1
           >2
           alist->hash-table
           diff
           dump-file
           dump-output
           eat-one-space
           eat-one-space-or-newline
           f-is-null
           fand
           for
           gulp-file
           gulp-port
           hash-read-string
           hash-table->alist
           join
           list<
           null-is-#f
           one-is-#f
           pretty-string
           stderr
           stdout
           string-sub
           symbol<
           symbol-capitalize
           
           ;; FIXME

           comma-join
           comma-nl-join
           comma-space-join
           double-colon-join
           nl-comma-join
           pipe-join
           ))

(define *eof* (call-with-input-string "" read-char))
(define (null-is-#f o) (if (null? o) #f o))
(define (f-is-null o) (if o o '()))
(define (*eof*-is-#f o) (if (eq? *eof* o) #f o))
(define (one-is-#f o) (if (or (null? o) (=1 (length o))) #f o))

(define (=0 x) (= x 0))
(define (>0 x) (> x 0))
(define (=1 x) (= x 1))
(define (>1 x) (> x 1))
(define (=2 x) (= x 2))
(define (>2 x) (> x 2))

(define (symbol-capitalize symbol)
  ((compose string->symbol string-capitalize symbol->string) symbol))

(define (symbol< a b) (string< (symbol->string a) (symbol->string b)))
(define (list< a b)
  (if (null? a)
      (not (null? b))
      (if (null? b)
          #f
          (if (eq? (car a) (car b))
              (list< (cdr a) (cdr b))
              (if (pair? (car a))
		  (list< (car a) (car b))
		  (symbol< (car a) (car b)))))))

(define (fand . args)
  (eval `(and ,@args) (current-module)))

(define (for . args)
  (eval `(or ,@args) (current-module)))

(define (dump-file file-name string)
  (let* ((file (open-output-file (->string file-name))))
    (display string file)
    (close file)))

(define (dump-output file-name thunk)
  (dump-file (->string file-name)
             (with-output-to-string thunk)))

(define (gulp-file file-name)
  (gulp-port (open-input-file (->string file-name))))

(define (gulp-file-binary file-name)
  (call-with-input-file (->string file-name) get-bytevector-all))

(define (gulp-port . port) 
  (or (and-let* ((result (read-delimited "" (if (pair? port) (car port) (current-input-port))))
                 ((string? result)))
                result)
      ""))

(define (logf port string . rest)
  (apply format (cons* port string rest))
  (force-output port)
  #t)
  
(define (stderr string . rest)
  (apply logf (cons* (current-error-port) string rest)))

(define (stdout string . rest)
  (apply logf (cons* (current-output-port) string rest)))

(define (->string h . t)
  (let ((src (if (pair? t) (cons h t) h))) 
    (match src
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ((? symbol?) (symbol->string src))
      ((h ... t) (apply string-append (map ->string src)))
      (_ ""))))

(define (flatten x)
  "unnest list."
  (let loop ((x x) (tail '()))
    (cond ((list? x) (fold-right loop tail x))
          ((not (pair? x)) (cons x tail))
          (else (loop (car x) (loop (cdr x) tail))))))

(define ((->join infix) lst) (string-join (filter (negate string-null?) (map ->string lst)) infix))

;; JUNKME, just use ((->join INFIX) lst)
(define (comma-join lst) ((->join ",") lst))
(define (comma-nl-join lst) ((->join ",\n") lst))
(define (comma-space-join lst) ((->join ", ") lst))
(define (double-colon-join lst) ((->join "::") lst))
(define (nl-comma-join lst) ((->join "\n  , ") lst))
(define (pipe-join lst) ((->join " | ") lst))


(define (eat-one-space)
  (let ((c (read-char)))
    (cond
     ((eq? c #\space) #t)
     ((eq? *eof* c) #f)
     (else (unread-char c)))))

(define (eat-one-space-or-newline)
  (let ((c (read-char)))
    (cond
     ((eq? c #\space) #t)
     ((eq? c #\newline) #t)
     ((eq? *eof* c) #f)
     (else (unread-char c)))))

(define (hash-read-string chr port)
  (eat-one-space-or-newline)
  (with-output-to-string
    (lambda ()
      (let ((depth 1))
        (while (and-let* (((>0 depth))
                          (s (*eof*-is-#f (read-delimited "#" port))))
                         (display s))
          (let ((c (peek-char port)))
            (cond
             ((eq? c #\{) (set! depth (1+ depth)) (display "#"))
             ((eq? c #\}) (set! depth (1- depth)) (if (=0 depth)
                                                      (read-char port)
                                                      (display "#")))
             ((eq? *eof* c) (set! depth 0) #f)
             (else (display "#")))))))))

(define (pretty-string scm)
  (with-output-to-string (lambda () (pretty-print scm))))

(define (string-sub re sub string)
  (regexp-substitute/global #f re string 'pre sub 'post))

(define* (diff a b :optional (options "-u") (virtual-name-a "a") (virtual-name-b "b"))
  (let ((file-name-a (fifo a))
        (file-name-b (fifo b)))
    (string-sub file-name-a virtual-name-a
                (string-sub file-name-b virtual-name-b
                            (gulp-port (cdr (run-with-pipe "r" "diff" options file-name-a file-name-b)))))))

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

