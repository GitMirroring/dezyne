;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2017, 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag parse)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 rdelim)

  #:use-module (gaiag command-line)
  #:use-module (gaiag parse peg)
  #:use-module (gaiag parse ast)
  #:use-module (gaiag parse peg)
  #:use-module (gaiag wfc)

  #:export (file->ast
            string->ast
            peg:handle-syntax-error))

(define (peg:line-number string pos)
  (1+ (string-count string #\newline 0 pos)))

(define (peg:column-number string pos)
  (- pos (or (string-rindex string #\newline 0 pos) -1)))

(define (peg:line string pos)
  (let ((start (1+ (or (string-rindex string #\newline 0 pos) -1)))
        (end (or (string-index string #\newline pos) (string-length string))))
    (substring string start end)))

(define (peg:error file-name string pos message)
  (let* ((ln (peg:line-number string pos))
         (col (peg:column-number string pos))
         (line (peg:line string pos))
         (indent (make-string (1- col) #\space)))
    (format (current-error-port) "~a:~a:~a: error\n~a\n~a^\n~a~a\n"
            file-name
            ln col line
            indent
            indent
            message)
      (throw 'syntax-error '())))

(define (peg:handle-syntax-error file-name string)
  (lambda (key . args)
    (let* ((pos (caar args))
           (message (format #f "`~a' expected" (cadar args))))
      (peg:error file-name string pos message))))

(define* (parse-string string #:key (file-name "-") (imports '()))
  (let* ((parse-tree (catch 'syntax-error
                            (lambda ()
                              (parameterize ((%peg:locations? #t)
                                             (%peg:skip? peg:skip-parse)
                                             (%peg:debug? (gdzn:command-line:get 'debug)))
                                (peg:parse string file-name #:imports imports)))
                       (peg:handle-syntax-error file-name string)))
         (gdzn-debug? (gdzn:command-line:get 'debug)))
    (parse-root->ast parse-tree #:string string #:file-name file-name)))

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
