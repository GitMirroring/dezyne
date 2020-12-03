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
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn command-line)
  #:use-module (dzn parse)
  #:use-module (dzn parse complete)
  #:use-module (dzn parse lookup)
  #:use-module (dzn parse tree)
  #:use-module (dzn parse util)
  #:use-module (dzn parse peg)

  #:export (main))

(define* (and+pred=> value proc #:optional pred)
  (cond ((and value pred) (if (pred value) (proc value) #f))
        (value (proc value))
        (else #f)))

(define (locus file-name line col str)
  (if (not (string? str)) (format #f "~a:~a:~a:" file-name line col)
      (let ((l (+ line (string-count str #\newline)))
            (c (- (string-length str) (or (string-rindex str #\newline) 0))))
        (if (= line l) (format #f "~a:~a:~a-~a:" file-name line col c)
            (format #f "~a:~a:~a-~a:~a:" file-name line col l c)))))

(define (parse-opts args)
  (let* ((option-spec
          '((complete (single-char #\c))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (lookup (single-char #\l))
            (offset (value #t))
            (point (single-char #\p) (value #t))
            (verbose (single-char #\v))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn language [OPTION]... FILE
Dezyne language tool for completion and lookup information

 -c, --complete                  show completions [default]
 -h, --help                      display this help and exit
 -l, --lookup                    show lookup
 -I, --import=DIR+               add DIR to import path
     --offset=OFFSET             use offset=OFFSET to determine context
 -p, --point=LINE[,COLUMN]       calculate offset from line LINE and column COLUMN [0]
 -v, --verbose                   display input, parse tree, offset, context and completions
"))
      (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS)))
    options))

(define (main args)
  (define (string->point str)
    (match (map string->number (string-split str (char-set #\, #\space)))
      ((line column) (values line column))
      ((line) (values line 0))))

  (let* ((options (parse-opts args))
         (verbose? (option-ref options 'verbose #f))
         (debugity (dzn:debugity))
         (file-name (and+pred=> (option-ref options '() #f) last pair?))
         (imports (multi-opt options 'import))
         (imports (delete-duplicates (cons* (dirname file-name) "." imports)))
         (help? (option-ref options 'help #f))
         (lookup? (option-ref options 'lookup #f)))

    (define (file-name->parse-tree file-name)
      (let* ((file (search-path imports file-name))
             (text (with-input-from-file file
                     read-string)))
        (parameterize ((%peg:fall-back? #t))
          (string->parse-tree text #:file-name file-name))))
    (define (file-name->text file-name)
      (let ((file-name (search-path imports file-name)))
        (with-input-from-file file-name read-string)))
    (let* ((input (file-name->text file-name))
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
           (offset (or (and+pred=> (option-ref options 'offset #f) string->number)
                       (and+pred=> (option-ref options 'point #f) (lambda (str)
                                                                    (call-with-values (cute string->point str)
                                                                      (lambda (line col) (line-column->offset line col input)))))
                       (car parse-result)))
           (parse-tree (cdr parse-result)))
      (let ((context (complete:context parse-tree offset)))
        (when (> debugity 2)
          (display "input:\n" (current-error-port ))
          (display input (current-error-port))
          (display "parse-tree:\n" (current-error-port))
          (pretty-print parse-tree (current-error-port))
          (display "offset: " (current-error-port))
          (pretty-print offset (current-error-port)))
        (when (> debugity 1)
          (display "context:\n" (current-error-port))
          (pretty-print context (current-error-port)))
        (cond
         (lookup?
          (let* ((token (.tree context))
                 (def   (lookup-definition
                         token context
                         #:file-name file-name
                         #:file-name->parse-tree file-name->parse-tree)))
            (when (> debugity 0)
              (display "definition:\n" (current-error-port))
              (pretty-print def (current-error-port)))
            (when verbose?
              (display "location:\n"))
            (let ((loc (match def
                         ((file declaration)
                          (let* ((file-name (or file file-name))
                                 (text      (file-name->text file-name)))
                            (lookup->location def text #:file-name file-name)))
                         (_ #f))))
              (unless loc
                (display "not found\n")
                (exit EXIT_FAILURE))
              (display (location->string loc))
              (newline))))
         (else
          (when verbose?
            (display "completions:\n"))
          (pretty-print (complete (.tree context) context offset))))))))
