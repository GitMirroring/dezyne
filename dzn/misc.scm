;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (dzn fifo)
  #:use-module (dzn command-line)
  #:use-module (dzn shell-util)

  #:export (
            ;;goops-prefix
           *eof*
           *eof*-is-#f
           ->join
           symbol-join
           ->string-join
           ->string
           !=
           <1
           <2
           =0
           =1
           =2
           >=1
           >=2
           >0
           >1
           >2
           2+
           2-
           alist->hash-table
           components->file-name
           file-name->components
           diff
           drop-prefix
           dump-string
           dump-output
           eat-one-space
           eat-one-space-or-newline
           f-is-null
           gulp-file
           gulp-pipe
           gulp-pipe*
           gulp-port
           hash-read-string
           hash-table->alist
           null-is-#f
           number->symbol
           one-is-#f
           pke
           pretty-string
           regex-split
           stderr
           stdout
           string-null-is-#f
           string-postfix?
           string-sub ;; FIXME: look at guile-lib string-substitute sugar
           null-symbol
           symbol-null?
           pair??
           eq??
           equal??
           symbol-upcase-first
           symbol-drop-right

           ;; FIXME

           comma-join
           comma-nl-join
           comma-space-join
           double-colon-join
           nl-comma-join
           pipe-join
           disjoin
           conjoin
           ))

(define (disjoin . predicates)
  (lambda (. arguments)
    (any (cut apply <> arguments) predicates)))

(define (conjoin . predicates)
  (lambda (. arguments)
    (every (cut apply <> arguments) predicates)))

(define *eof* (call-with-input-string "" read-char))
(define (null-is-#f o) (if (null? o) #f o))
(define (pair?? o) (and (pair? o) o))
(define (eq?? h . t) (and (apply eq? (cons h t)) h))
(define (equal?? h . t) (and (apply equal? (cons h t) h)))
(define (string-null-is-#f o) (if (string-null? o) #f o))
(define (f-is-null o) (if o o '()))
(define (*eof*-is-#f o) (if (eq? *eof* o) #f o))
(define (one-is-#f o) (if (or (null? o) (=1 (length o))) #f o))

(define (!= a b) (not (= a b)))
(define (<1 x) (< x 1))
(define (<2 x) (< x 2))
(define (=0 x) (= x 0))
(define (>0 x) (> x 0))
(define (=1 x) (= x 1))
(define (>1 x) (> x 1))
(define (>=1 x) (>= x 1))
(define (=2 x) (= x 2))
(define (>2 x) (> x 2))
(define (>=2 x) (>= x 2))
(define (2+ x) (+ x 2))
(define (2- x) (- x 2))

(define null-symbol (string->symbol ""))
(define (symbol-null? x) (eq? x null-symbol))
(define (number->symbol x) (string->symbol (number->string x)))

(define (drop-prefix prefix lst)
  (let loop ((prefix prefix) (lst lst))
    (if (or (null? prefix) (null? lst) (not (eq? (car prefix) (car lst)))) lst
        (loop (cdr prefix) (cdr lst)))))

(define* (symbol-join lst #:optional (sep '.))
  (string->symbol (string-join  (map symbol->string lst) (symbol->string sep))))

(define ((->string-join infix) lst)
  (let loop ((lst lst) (result '()))
    (if (null? lst) (apply string-append result)
        (if (null? result)
            (loop (cdr lst) (take lst 1))
            (loop (cdr lst) (append result (list infix) (take lst 1)))))))

(define (symbol-upcase-first sym)
   (let ((str (symbol->string sym)))
     (string-append (string-upcase (string-take str 1)) (string-drop str 1))))

(define (symbol-drop-right symbol count)
  (define ((drop count) string) (string-drop-right string count))
  ((compose string->symbol (drop count) symbol->string) symbol))

(define (symbol-take symbol count)
  (define ((take count) string) (string-take string count))
  ((compose string->symbol (take count) symbol->string) symbol))

(define (join-components components)
  (apply
   string-append
   (let loop ((components components))
     (if (null? components)
         '()
         (let ((separator (if (and (>1 (length components))
                                   (not (and (string-prefix? "." (cadr components))
                                             (=2 (length components)))))
                              "/" "")))
           (append (list (car components) separator)
                   (loop (cdr components))))))))

(define (file-name->components file-name)
  (map string->symbol (string-split file-name #\/)))

(define (components->file-name- components)
  (join-components (map ->string components)))

(define (components->file-name components)
  (if (pair? components)
      (components->file-name- components)
      (->string components)))

(define* (regexp-split regex str #:optional (flags 0))
  (let ((ret (fold-matches
              regex str (list '() 0 str)
              (lambda (m prev)
                (let* ((ll (car prev))
                       (start (cadr prev))
                       (tail (match:suffix m))
                       (end (match:start m))
                       (s (substring/shared str start end))
                       (groups (map (lambda (n) (match:substring m n))
                                    (iota (1- (match:count m)) 1))))
                  (list `(,@ll ,s ,@groups) (match:end m) tail)))
              flags)))
    `(,@(car ret) ,(caddr ret))))

(define (dump-string file-name string)
  (dump-output file-name (lambda () (display string))))

(define (dump-output file-name thunk) ; JUNKME
  (let ((dir (command-line:get 'output)))
    (cond ((or (eq? file-name #t)
               (equal? file-name "-")
               (equal? dir "-")) (thunk))
          ((not file-name) (with-output-to-string thunk))
          (else (let* ((dir (and dir (string-index dir #\/) dir))
                       (file-name (cond ((not dir) file-name)
                                       ((pair? file-name) (cons dir file-name))
                                       (else (cons dir (list file-name)))))
                       (name (components->file-name file-name)))
                 (mkdir-p (dirname name))
                 (with-output-to-file name thunk))))))

(define (gulp-file file-name)
  (with-input-from-file (components->file-name file-name) read-string))

(define (gulp-pipe command)
  (let* ((port (open-pipe command OPEN_READ))
         (output (read-string port))
         (status (close-pipe port)))
    (if (zero? status) (string-trim-right output #\newline)
        (error (format #f "pipe failed: ~s" command)))))

(define (gulp-pipe* . command)
  (let* ((port (apply open-pipe* OPEN_READ command))
         (output (read-string port))
         (status (close-pipe port)))
    (if (zero? status) (string-trim-right output #\newline)
        (error (format #f "pipe failed: ~s" command)))))

(define (logf port string . rest)
  (apply format (cons* port string rest))
  (force-output port)
  #t)

(define (stderr string . rest)
  (apply logf (cons* (current-error-port) string rest)))

(define (stdout string . rest)
  (apply logf (cons* (current-output-port) string rest)))

(define (pke . stuff)
  (newline (current-error-port))
  (display ";;; " (current-error-port))
  (write stuff (current-error-port))
  (newline (current-error-port))
  (car (last-pair stuff)))

(define (->string h . t)
  (let ((src (if (pair? t) (cons h t) h)))
    (match src
      (('def t ...) "")
      ((? char?) (make-string 1 src))
      ((? string?) src)
      ((? symbol?) (symbol->string src))
      ((? number?) (number->string src))
      ((h ... t) (apply string-append (map ->string src)))
      (_ ""))))

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

(define (string-postfix? postfix string)
  (and (<= (string-length postfix) (string-length string))
       (and (equal? postfix (string-take-right string (string-length postfix)))
            postfix)))

(define* (diff a b #:optional (options " -u") (virtual-name-a "a") (virtual-name-b "b"))
  (let ((file-name-a (fifo a))
        (file-name-b (fifo b)))
    (string-sub file-name-a virtual-name-a
                (string-sub file-name-b virtual-name-b
                            (gulp-pipe (string-append "diff" options " "file-name-a " " file-name-b))))))

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
