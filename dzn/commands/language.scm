;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn commands language)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn command-line)
  #:use-module (dzn parse)
  #:use-module (dzn parse complete)
  #:use-module (dzn parse tree)
  #:use-module (dzn parse util)
  #:use-module (dzn parse peg)

  #:export (main))

(define* (and=> value proc #:optional pred)
  (cond ((and value pred) (if (pred value) (proc value) #f))
        (value (proc value))
        (else #f)))

(define (locus file-name line col str)
  (if (not (string? str)) (format #f "~a:~a:~a:" file-name line col)
      (let ((l (+ line (string-count str #\newline)))
            (c (- (string-length str) (or (string-rindex str #\newline) 0))))
        (if (= line l) (format #f "~a:~a:~a-~a:" file-name line col c)
            (format #f "~a:~a:~a-~a:~a:" file-name line col l c)))))

(define (main args)
  (define (string->point str)
    (apply values (map string->number (string-split str (char-set #\, #\space)))))

  (let* ((options (getopt-long args
                               '((help (single-char #\h))
                                 (import (single-char #\I) (value #t))
                                 (offset (value #t))
                                 (point (single-char #\p) (value #t))
                                 (verbose (single-char #\v)))))
         (verbose? (option-ref options 'verbose #f))
         (file-name (and=> (option-ref options '() #f) last pair?))
         (help? (option-ref options 'help #f))
         (print-help (cute format (current-output-port)
                     "\
Usage: dzn language [OPTION]... FILE
Produce Dezyne language completion and location information

 -h, --help                      display this help and exit
 -I, --import=DIR+               add DIR to import path
     --offset=OFFSET             use offset=OFFSET to determine context
 -p, --point=LINE,COLUMN         calculate offset from line=LINE and column=COLUMN
 -v, --verbose                   display input, parse tree, offset, context and completions
")))
    (cond
     (help? (print-help))
     (file-name
      (let* ((input (with-input-from-file file-name read-string))
             (errors '())
             (parse-result (parameterize
                               ((%peg:debug? (> (dzn:debugity) 0))
                                (%peg:locations? #t)
                                (%peg:skip? peg:skip-parse)
                                (%peg:fall-back? #t)
                                (%peg:error (lambda (pos str error)
                                              (when (< pos (1- (string-length str)))
                                                (set! errors (cons errors (list pos str error)))
                                                (let ((line (1+ (string-count str #\newline 0 pos)))
                                                      (col (- pos (or (string-rindex str #\newline 0 pos) 0))))
                                                  (format (current-error-port) "~a ~a\n"
                                                          (locus file-name line col (second error))
                                                          error))))))
                             (cons (string-length input) (string->parse-tree input #:file-name file-name))))
             (offset (or (and=> (option-ref options 'offset #f) string->number)
                         (and=> (option-ref options 'point #f) (lambda (str)
                                                                 (call-with-values (cute string->point str)
                                                                   (lambda (line col) (line-column->offset line col input)))))
                         (car parse-result)))
             (parse-tree (cdr parse-result)))
        (let ((context (complete:context parse-tree offset)))
          (when verbose?
            (display "input:\n") (format #t input)
            (display "parse-tree:\n") (pretty-print parse-tree)
            (display "offset: ") (pretty-print offset))
          (when verbose?
            (display "context:\n") (pretty-print context)
            (display "completions:\n"))
          (pretty-print (complete (.tree context) context offset)))))
     (else (print-help)))))
