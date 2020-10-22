;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2017, 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 202 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn parse)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 pretty-print)

  #:use-module (dzn command-line)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse ast)
  #:use-module (dzn parse peg)
  #:use-module (dzn wfc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:export (file->ast
            string->ast
            peg:handle-syntax-error
            preprocess))

(define (peg:line-number string pos)
  (1+ (string-count string #\newline 0 pos)))

(define (peg:column-number string pos)
  (- pos (or (string-rindex string #\newline 0 pos) -1)))

(define (peg:line string pos)
  (let ((start (1+ (or (string-rindex string #\newline 0 pos) -1)))
        (end (or (string-index string #\newline pos) (string-length string))))
    (substring string start end)))

(define (peg:message file-name string pos error message)
  (let* ((line-number (peg:line-number string pos))
         (column-number (peg:column-number string pos))
         (line (peg:line string pos))
         (indent (make-string (1- column-number) #\space))
         (hanging (string-append indent message)))
    (string-append
     (format #f "~a:~a:~a: ~a\n~a\n~a^\n"
             file-name line-number column-number
             error line indent)
     (if (string-null? hanging) ""
         (string-append hanging "\n")))))

(define* (peg:error-message file-name string pos message)
    (display (peg:message file-name string pos "error" message) (current-error-port)))

(define* (peg:handle-error file-name string pos message #:key (key 'syntax-error))
  (peg:error-message file-name string pos message)
  (throw key '()))

(define (peg:syntax-error-message file-name string args)
  (unless (or (null? args) (null? (car args)))
    (let* ((pos (caar args))
           (message (format #f "`~a' expected" (cadar args))))
      (peg:error-message file-name string pos message))))

(define (peg:handle-syntax-error file-name string)
  (lambda (key . args)
    (if (or (null? args) (null? (car args))) (apply throw key args)
        (begin
          (peg:syntax-error-message file-name string args)
          (apply throw key '())))))

(define* (parse-string string #:key (file-name "-") (imports '()))
  (let* ((parse-tree (catch 'syntax-error
                       (lambda ()
                         (parameterize ((%peg:locations? #t)
                                        (%peg:skip? peg:skip-parse)
                                        (%peg:debug? (> (gdzn:debugity) 3)))
                           (peg:parse string file-name #:imports imports)))
                       (peg:handle-syntax-error file-name string)))
         (gdzn-debug? (gdzn:command-line:get 'debug)))
    (when (> (gdzn:debugity) 2)
      (pretty-print parse-tree (current-error-port)))
    (let* ((ast (parse-tree->ast parse-tree #:string string #:file-name file-name))
           (ast (annotate-ast ast)))
      (when (> (gdzn:debugity) 1)
        (pretty-print ast  (current-error-port)))
    ast)))

(define* (file->ast file-name #:key peg? (imports '()))
  (let* ((string (if (equal? file-name "-") (read-string)
                     (with-input-from-file file-name read-string)))
         (imports (if (equal? file-name "-") '()
                      (cons (dirname (canonicalize-path file-name)) imports)))
         (ast (parse-string string #:file-name file-name #:imports imports)))
    (if peg? ast
        (ast:wfc ast))))

(define* (string->ast string #:key peg?)
  (let ((ast (parse-string string)))
    (if peg? ast
        (ast:wfc ast))))

(define* (preprocess file-name #:key (imports '()))
  "Read @var{file-name}, using @var{imports} to resolve @code{import}
statements and return the expanded dezyne text, similar to @command{gcc
-E}."
  (define (preprocess-helper file-names imports read)
    (define (import-file import-line)
      (string-trim-both
       (string-drop-right
        (string-drop (string-trim-both import-line) (string-length "import "))
        1)))

    (define (import? line)
      (string-prefix? "import " (string-trim-both line)))

    (define (comment-import-line line)
      (if (import? line) (string-append "//" line) line))

    (if (null? file-names) ""
        (let ((file-name (search-path imports (car file-names))))
          (unless file-name
            (throw 'import-error
                   (car file-names) (string-join imports)))
          (let* ((canonical-name (canonicalize-path file-name))
                 (lines (if (member canonical-name read) '()
                            (string-split
                             (with-input-from-file file-name read-string)
                             #\newline))))
            (string-join
             `(,@(if (null? lines) '()
                     `(,(string-append (if (null? read) "#file " "#imported ")
                                       "\"" file-name "\"")))
               ,@(map comment-import-line lines)
               ,(preprocess-helper
                 (append (cdr file-names)
                         (map import-file (filter import? lines)))
                 (cons (dirname canonical-name) imports)
                 (cons canonical-name read)))
             "\n")))))

  (preprocess-helper (list (basename file-name))
                     (cons (dirname file-name) imports)
                     '()))
