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
  :use-module (ice-9 rdelim)
  :export (
           =0
           >0
           =1
           >1
           >2
           eat-one-space
           eat-one-space-or-newline
           fand
           f-is-null
           for
           gulp-text-file
           hash-read-string
           dump-file
           *eof*
           *eof*-is-#f
           join
           null-is-#f
           one-is-#f
           stderr
           stdout
           symbol<
           list<
           ->string
           
           ;; FIXME
           ->join
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
(define (>2 x) (> x 2))

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

(define (gulp-text-file name)
  (let* ((file (open-file (->string name) "r"))
	 (text (read-delimited "" file)))
    (close file)
    text))

(define (dump-file name string)
  (let* ((file (open-output-file (->string name))))
    (display string file)
    (close file)))

(define (logf port string . rest)
  (apply format (cons* port string rest))
  (force-output port)
  #t)
  
(define (stderr string . rest)
  (apply logf (cons* (current-error-port) string rest)))

(define (stdout string . rest)
  (apply logf (cons* (current-output-port) string rest)))

(define (->string src)
  (match src
    ((? char?) (make-string 1 src))
    ((? string?) src)
    ((? symbol?) (symbol->string src))
    ((h ... t) (apply string-append (map ->string src)))
    (_ "")))

(define-public (flatten x)
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

