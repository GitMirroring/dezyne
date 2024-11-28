;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020, 2021, 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn commands parse)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)

  #:use-module (dzn ast)
  #:use-module (dzn ast display)
  #:use-module (dzn ast serialize)
  #:use-module (dzn ast wfc)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse util)
  #:use-module (dzn peg util)

  #:export (parse
            parse-opts
            preprocess
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((fall-back (single-char #\f))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (list-models (single-char #\l))
            (locations (single-char #\L))
            (no-directives (single-char #\D))
            (preprocess (single-char #\E))
            (parse-tree (single-char #\t))
            (output (single-char #\o) (value #t))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f))
         (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn parse [OPTION]... [FILE]...
Parse a Dezyne file and produce an AST

  -D, --no-directives    do not include file-directives in content stream
  -f, --fall-back        use fall-back parser
  -E, --preprocess       resolve imports and produce content stream
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -l, --list-models      print the name of each model in FILE
  -L, --locations        show locations in output AST
  -m, --model=MODEL      generate ast for MODEL
  -t, --parse-tree       write PEG parse tree
  -o, --output=FILE      write AST to FILE (\"-\" for standard output)
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (string->transformation name)
  (let* ((transform (resolve-interface `(dzn transform)))
         (input (open-input-string name))
         (name (false-if-exception (read input)))
         (transformation (false-if-exception
                          (module-ref transform name)))
         (parameters (false-if-exception (read input)))
         (parameters (if (pair? parameters) parameters '()))
         (parameters? (and (pair? parameters)
                           (match (procedure-minimum-arity transformation)
                             ((1 0 optional) #f)
                             (_ #t)))))
    (unless transformation
      (throw 'error (format #f "no such transformation: ~a" name)))
    (if parameters? (cute transformation <> parameters)
        transformation)))

(define* (parse options file-name #:key (exit? #t))
  (let* ((debug? (dzn:command-line:get 'debug #f))
         (skip-wfc? (dzn:command-line:get 'skip-wfc #f))
         (imports (command-line:get 'import))
         (locations? (command-line:get 'locations))
         (model-name (option-ref options 'model #f))
         (transform (dzn:multi-opt 'transform)))
    (parameterize ((%locations? locations?)
                   (%peg:error (peg:format-display-syntax-error file-name)))
      (parse:call-with-handle-exceptions
       (lambda _
         (let* ((ast (parse:file->ast file-name #:imports imports))
                (ast (if skip-wfc? ast
                         (ast:wfc ast)))
                (transform (map string->transformation transform))
                (ast (fold (lambda (transform ast)
                             (transform ast))
                           ast
                           transform)))
           ast))
       #:backtrace? debug?
       #:exit? exit?
       #:file-name file-name))))

(define (parse-tree options file-name)
  (let ((debug? (dzn:command-line:get 'debug #f))
        (imports (command-line:get 'import))
        (fall-back? (command-line:get 'fall-back)))
    (parameterize ((%peg:fall-back? fall-back?)
                   (%peg:error (peg:format-display-syntax-error file-name)))
      (parse:call-with-handle-exceptions
       (lambda _ (parse:file->tree-alist file-name #:imports imports))
       #:backtrace? debug?
       #:exit? #f
       #:file-name file-name))))

(define (preprocess options file-name)
  (let ((debug? (dzn:command-line:get 'debug #f))
        (directives? (not (command-line:get 'no-directives)))
        (imports (command-line:get 'import)))
    (parse:call-with-handle-exceptions
     (lambda _ (parse:file->stream file-name #:imports imports
                                   #:file-directives? directives?))
     #:backtrace? debug?
     #:exit? #f
     #:file-name file-name)))

(define (display-models file-name)
  (let* ((debug? (dzn:command-line:get 'debug #f))
         (models (parse:call-with-handle-exceptions
                  (cute list-models-name+type file-name)
                  #:backtrace? debug?
                  #:file-name file-name)))
    (for-each (match-lambda
                ((model . type)
                 (simple-format #t "~a ~a\n" model type)))
              models)))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (and (pair? files) (car files)))
         (list-models? (command-line:get 'list-models))
         (debug? (dzn:command-line:get 'debug))
         (fall-back? (command-line:get 'fall-back))
         (output? (option-ref options 'output #f))
         (output-file-name (option-ref options 'output "-"))
         (parse-tree? (command-line:get 'parse-tree))
         (preprocess? (option-ref options 'preprocess #f))
         (no-directives? (command-line:get 'no-directives))
         (verbose? (dzn:command-line:get 'verbose)))
    (cond
     (list-models?
      (display-models file-name))
     ((or parse-tree? fall-back?)
      (let ((tree (parse-tree options file-name)))
        (if (and tree output?)
            (if (equal? output-file-name "-") (pretty-print tree)
                (with-output-to-file file-name (cut pretty-print tree)))
            (when (and verbose? (not fall-back?))
              (if tree (display "parse: no errors found\n")
                  (display "parse: errors found\n"))))
        (unless tree
          (exit EXIT_FAILURE))))
     ((or preprocess?
          no-directives?)
      (let ((tree (preprocess options file-name)))
        (if tree (display tree)
            (exit EXIT_FAILURE))))
     (else
      (let ((ast (parse options file-name #:exit? #f)))
        (if (and ast output?)
            (let* ((file-name (option-ref options 'output "-"))
                   (locations? (command-line:get 'locations))
                   (sexp (and (not debug?)
                              (parameterize ((%locations? locations?))
                                (ast:serialize ast))))
                   (width (or (and=> (getenv "COLUMNS") string->number)
                              79))
                   (output (with-output-to-string
                             (if debug? (cut ast:pretty-print ast #:width width)
                                 (cut pretty-print sexp #:width width)))))
              (if (equal? file-name "-") (display output)
                  (with-output-to-file file-name (cut display output))))
            (when verbose?
              (if ast (display "parse: no errors found\n")
                  (display "parse: errors found\n"))))
        (unless ast
          (exit EXIT_FAILURE)))))))
